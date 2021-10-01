
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', async () => {
            let airlineName = DOM.elid('airline-name').value;
            await contract.registerAirline(airlineName).catch(e => {
                console.error(e);
                throw e;
            })
            alert(`${airlineName} Airline has been Successfully Registered!`)
            // Write transaction
            // contract.fetchFlightStatus(flight, (error, result) => {
            //     display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            // });
        })

        DOM.elid('get-balance').addEventListener('click', async () => {
            let balance = await contract.getBalance();
            alert(`The Balance is: ${balance} Ether`)
        })

        DOM.elid('authorize-contract').addEventListener('click', async () => {
            await contract.authorizeAppContract().catch(e => {
                alert(e)
                throw e
            })
            alert('App Contract is Authorized!')
        })

        DOM.elid('register-flight').addEventListener('click', async () => {
            let dateString = DOM.elid('timestamp').value
            let flightName = DOM.elid('flight-name').value
            let timestamp = Date.parse(dateString)

            if (timestamp == NaN) {
                let msg = 'Invalid Date String.'
                alert(msg)
                throw msg
            }
            await contract.registerFlight(timestamp, flightName).catch(e => {
                throw e
            })
            alert(`Flight ${flightName} has been Successfully Registered!`)
        })

        DOM.elid('fund-airline').addEventListener('click', async () => {
            // todo check for digit
            let amount = DOM.elid('amount').value

            if (isNaN(amount)) {
                let msg = 'Invalid Ether Amount Entered!'
                alert(msg)
                throw msg
            }
            await contract.fundAirline(amount).catch(e => {
                alert('Failed to fund Airline. You need to fund at least 10 Ether.')
                throw e
            })
            alert(`${amount} Ether Funded!`)
        })

        DOM.elid('buy-insurance').addEventListener('click', async () => {
            let dateString = DOM.elid('timestamp-insurance').value
            let flightName = DOM.elid('flight-name-insurance').value
            let timestamp = Date.parse(dateString)

            if (timestamp == NaN) {
                let msg = 'Date String is Invalid.'
                alert(msg)
                throw msg
            }
            await contract.buyInsurance(flightName, timestamp).catch(e => {
                alert(e)
                throw e
            })
            alert('Insurance Bought Successfully!')
        })

        DOM.elid('claim-insurance').addEventListener('click', async () => {
            let dateString = DOM.elid('timestamp-claim').value
            let flightName = DOM.elid('flight-name-claim').value
            let timestamp = Date.parse(dateString)

            if (timestamp == NaN) {
                let msg = 'Date String is Invalid.'
                alert(msg)
                throw msg
            }
            await contract.fetchFlightStatus(flightName, timestamp).catch(e => {
                alert(e)
                throw e
            })
            alert('You have Successfully Claimed Insurance. If you were already paid eariler, no action shall take place and the server will log the error.')
        })
    
    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







