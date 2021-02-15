import { Elm } from './Main.elm';
import 'regenerator-runtime/runtime'

// let auth0 = null;

// const fetchAuthConfig = () => fetch("/auth_config.json");

// const configureClient = async () => {
//   const response = await fetchAuthConfig();
//   const config = await response.json();

//   auth0 = await createAuth0Client({
//     domain: config.domain,
//     client_id: config.clientId
//   });
// };


// window.onload = async () => {
//   const response = await fetch('https://goodtimes-staging.us.auth0.com/authorize?response_type=code&client_id=68MpVR1fV03q6to9Al7JbNAYLTi2lRGT&connection=google-oauth2&redirect_uri=http://localhost:1234&scope=openid%20name%20email')
//   console.log(response)
// }
//   await configureClient();
//   const isAuthenticated = await auth0.isAuthenticated();

//   if (!isAuthenticated) {
//     // const result = await auth0.loginWithRedirect({
//     //   redirect_uri: 'http://localhost:1234/'
//     // });
//   } else {
//     const user = await auth0.getUser();
//   }

//   console.log(isAuthenticated)

const startingAccessToken = localStorage.getItem('accessToken')

const app = Elm.Main.init({
  node: document.getElementById('mount'),
  flags: { maybeAccessToken: startingAccessToken }
})

app.ports.saveAccessToken.subscribe( function(accessToken) {
    localStorage.setItem('accessToken', accessToken);
});

app.ports.removeAccessToken.subscribe( function(accessToken) {
    localStorage.removeItem('accessToken', accessToken);
});

