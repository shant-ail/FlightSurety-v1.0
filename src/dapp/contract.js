import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        this.appAddress = config.appAddress;
        this.dataAddress = config.dataAddress;
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
           
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    async isOperational(callback) {
       let accounts = await this.web3.eth.getAccounts();
       console.log("Accounts: ${accounts[0]}");
       this.flightSuretyApp.methods.isOperational().call(callback);
    //    self.flightSuretyApp.methods
    //         .isOperational()
    //         .call({ from: self.owner}, callback);
    }

    async fetchFlightStatus(flight, timestamp) {
        let accounts = await this.web3.eth.getAccounts();
        return this.flightSuretyApp.methods.fetchFlightStatus(flight, timestamp).send({from: accounts[0]});
        
        // let self = this;
        // let payload = {
        //     airline: self.airlines[0],
        //     flight: flight,
        //     timestamp: Math.floor(Date.now() / 1000)
        // } 
        // self.flightSuretyApp.methods
        //     .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
        //     .send({ from: self.owner}, (error, result) => {
        //         callback(error, payload);
        //     });
    }

    async registerAirline(flightName)
    {
        let accounts = await this.web3.eth.getAccounts();
        let registrationFee = Web3.utils.toWei('1','ether');
        return this.flightSuretyApp.methods.registerAirline(flightName).send({from: accounts[0], value: registrationFee});
    }

    async registerFlight(timestamp, flightName)
    {
        let accounts = await this.web3.eth.getAccounts()
        return this.flightSuretyApp.methods.registerFlight(flightName, timestamp).send({from: accounts[0], gas: 150000});
    }

    async fundAirline(amount)
    {
        let accounts = await this.web3.eth.getAccounts();
        let weiAmount = Web3.utils.toWei(amount, 'ether');
        return this.flightSuretyApp.methods.fund().send({from: accounts[0], value: weiAmount});
    }

    async buyInsurance(flightName, timestamp)
    {
        let accounts = await this.web3.eth.getAccounts();
        let weiAmount = Web3.utils.toWei(amount, 'ether');
        return this.flightSuretyApp.methods.buyFlightInsurance(flightName, timestamp).send({from: accounts[0], value: weiAmount, gas: 150000});
    }

    async authorizeContract()
    {
        let accounts = await this.web3.eth.getAccounts();
        return this.flightSuretyData.methods.authorizeContracts(this.appAddress).send({from: accounts[0], gas: 150000})
    }

    async getBalance()
    {
        return this.web3.eth.getBalance(this.dataAddress);
    }

}