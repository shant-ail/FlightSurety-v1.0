
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeContracts(config.flightSuretyApp.address);
    await config.flightSuretyData.authorizeContracts(accounts[1]);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/


it(`should register, fund, and get an airline`, async function () {
    let registrationFee = web3.utils.toWei('1', 'ether')
    await config.flightSuretyApp.registerAirline('Asiana Airline', {from: accounts[1], value: registrationFee})
    let fund = web3.utils.toWei('10', 'ether')
    await config.flightSuretyApp.fund({from: accounts[1], value: fund})

    let result = await config.flightSuretyApp.getAirline.call({from: accounts[1]})
    assert.equal(result['0'], true, "success code should be true");
    assert.equal(result['1'], "Asiana Airline");
    assert.equal(web3.utils.fromWei(result[2].toString(), 'ether'), 10, "incorrect balance");

    console.log(`balance is ${web3.utils.fromWei(result[2].toString(), 'ether')} ether`)

    // register flight
    let now = Date.now()
    await config.flightSuretyApp.registerFlight('#KE-807', now, {from: accounts[1]})

    let flight = await config.flightSuretyApp.getFlight.call('#KE-807', now, {from: accounts[1]});

    assert.equal(flight[0], true, 'isRegistered')
    assert.equal(flight[1], 0, 'status coe')
    assert.equal(flight[2], '#KE-807', 'flight name')
    assert.equal(flight[3], now, 'timestamp')
    assert.equal(flight[4], accounts[1], 'airline address')


    // buy and get insurance
    let insuranceFee = web3.utils.toWei('1', 'ether')
    await config.flightSuretyApp.buyFlightInsurance('#KE-807', now, {from: accounts[1], value: insuranceFee});

    let insurance = await config.flightSuretyApp.getFlightInsurance.call('#KE-807', now, {from: accounts[1]});
    assert.equal(insurance[0], true, 'isRegistered')
    assert.equal(insurance[1], accounts[1], 'buyer address')
    assert.equal(web3.utils.fromWei(insurance[2], 'ether'), 1, "insurance value.");


});

});
