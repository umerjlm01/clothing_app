import { createClient } from '@supabase/supabase-js'
import { JWT } from 'google-auth-library'
import serviceAccount from '../service-account.json' with { type: 'json' }

interface Notification {
  id: string
  user_id: string
  body: string
}

interface WebhookPayload {
  type: 'INSERT'
  table: string
  record: Notification
  schema: 'public'
}

const supabaseUrl = Deno.env.get('MY_SUPABASE_URL')!
const supabaseKey = Deno.env.get('MY_SUPABASE_KEY')!

const supabase = createClient(supabaseUrl, supabaseKey)

Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json()

  if (payload.type !== 'INSERT' || payload.table !== 'notifications') {
    return new Response('Ignored', { status: 200 })
  }

  const { data } = await supabase
    .from('profiles')
    .select('fcm_token')
    .eq('id', payload.record.user_id)
    .single()

  if (!data?.fcm_token) {
    console.log('No FCM token for user:', payload.record.user_id)
    return new Response('No token', { status: 200 })
  }

  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

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
          notification: {
            title: 'New message',
            body: payload.record.body,
          },
        },
      }),
    }
  )

  const resData = await res.json()

  if (!res.ok) {
    console.error('FCM error:', resData)
  }

  return new Response(JSON.stringify(resData), {
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