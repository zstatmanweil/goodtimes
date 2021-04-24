import { Elm } from './Main.elm';
import 'regenerator-runtime/runtime'


const startingAccessToken = localStorage.getItem('accessToken')

if (process.env.NODE_ENV === 'production') { 
  var environment = 'production'
}

if (process.env.NODE_ENV === 'development') { 
  var environment = 'local'
}

const app = Elm.Main.init({
  node: document.getElementById('mount'),
  flags: {
    maybeAccessToken: startingAccessToken,
    environment,
  }
})

app.ports.saveAccessToken.subscribe( function(accessToken) {
    localStorage.setItem('accessToken', accessToken);
});

app.ports.removeAccessToken.subscribe( function(accessToken) {
    localStorage.removeItem('accessToken', accessToken);
});

