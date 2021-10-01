import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

(async() => {
  let registrationFee = await flightSuretyApp.methods.REGISTRATION_FEE().call().catch(e => {
      console.log('getting registration fee failed.')
      throw e
  });
  let oracleAccounts = (await web3.eth.getAccounts()).slice(10, 30);
  console.log(`regi fee ${registrationFee}`)
  console.log(`oracle accounts : ${oracleAccounts}`)
  oracleAccounts.forEach(async (oracleAccount, i) => {
      await flightSuretyApp.methods.registerOracle().send({from: oracleAccount, value: registrationFee, gas:3000000}).catch(e => {
          console.log('registerOracle failed')
          throw e
      })
      let oracleIndices = await flightSuretyApp.methods.getMyIndexes().call({from: oracleAccount}).catch(e => {
          console.log('get my indexes failed.')
          throw e
      })
      console.log(`${oracleAccount}, assigned indexes are ${oracleIndices[0]} ${oracleIndices[1]} ${oracleIndices[2]}`)
  })
})();

flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, async function (error, event) {
    if (error) 
    {
      console.log(error)
      throw error;
    }

    let reqIndex = event.returnValues.index
      console.log('---------- oracle request coming ----------')
      console.log(`index : ${reqIndex}`)
      console.log(`user address : ${event.returnValues.userAddress}`)
      console.log(`flight: ${event.returnValues.flight}`)
      console.log(`timestamp: ${event.returnValues.timestamp}`)


      let oracleAccounts = (await web3.eth.getAccounts()).slice(10, 30);
      oracleAccounts.forEach(async (oracleAccount) => {
          const STATUS_CODE_LATE_TECHNICAL = 40;
          let indices = await flightSuretyApp.methods.getMyIndexes().call({from: oracleAccount}).catch(e => {
              console.log('getMyIndexes failed.')
              throw e
          })

          if (indices[0] == reqIndex || indices[1] == reqIndex || indices[2] == reqIndex) {
              await flightSuretyApp.methods.submitOracleResponse(reqIndex, event.returnValues.userAddress,
                  event.returnValues.flight, event.returnValues.timestamp, STATUS_CODE_LATE_TECHNICAL)
                  .send({from: oracleAccount}).catch(e => {
                      console.log('submit Oracle Response failed.')
                      throw e
                  })

              console.log(`submit response: address ${event.returnValues.userAddress}, flight ${event.returnValues.flight}`)
          }
      })
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


