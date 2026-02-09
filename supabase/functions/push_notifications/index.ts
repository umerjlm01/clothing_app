import { createClient } from '@supabase/supabase-js'
import { JWT } from 'google-auth-library'
import serviceAccount from '../service-account.json' with { type: 'json' }

interface PushRequest {
token?: string // optional user JWT
receiver_id: string
title: string
body: string
conversation_id?: string
}

const supabaseUrl = Deno.env.get('MY_SUPABASE_URL')!
const supabaseKey = Deno.env.get('MY_SUPABASE_KEY')!

const supabase = createClient(supabaseUrl, supabaseKey)

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  let payload: PushRequest

  try {
    payload = await req.json()
  } catch {
    return new Response('Invalid JSON', { status: 400 })
  }

  // 🔐 Optional: verify user token if provided
  if (!payload.token) {
    return new Response('Missing auth token', { status: 401 })
  }

  const { data: user, error: userError } = await supabase.auth.getUser(payload.token)
  if (userError || !user) {
    return new Response('Unauthorized', { status: 401 })
  }

  const { receiver_id, title, body, conversation_id } = payload

  if (!receiver_id || !title || !body) {
    return new Response('Missing fields', { status: 400 })
  }

  // 🔍 Get receiver FCM token
  const { data, error } = await supabase
    .from('profiles')
    .select('fcm_token')
    .eq('id', receiver_id)
    .single()

  if (error || !data?.fcm_token) {
    console.log('No FCM token for user:', receiver_id)
    return new Response('No FCM token', { status: 200 })
  }

  // 🔐 Get Firebase access token
  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

  // 📲 Send DATA-ONLY FCM
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: data.fcm_token,
          data: {
            title,
            body,
            conversation_id: conversation_id ?? '',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          android: { priority: 'high' },
        },
      }),
    }
)

const resData = await res.json()

if (!res.ok) {
    console.error('FCM error:', resData)
    return new Response(JSON.stringify(resData), { status: 500 })
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})

const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })

    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}
