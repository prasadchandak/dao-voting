import daoABI from '/contract/dao';

const contractAddress = '0xffdDbc2510Ec4d9c8010D353936B1357488b2EAD'; // Replace with your deployed contract address

const web3 = new Web3(window.ethereum);

document.addEventListener('DOMContentLoaded', async () => {
    await window.ethereum.enable();
    displayMembers();
});

document.getElementById('addMemberBtn').addEventListener('click', async () => {
    const newName = prompt('Enter member name:');
    if (newName) {
        try {
            const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
            const contract = new web3.eth.Contract(daoABI, contractAddress);
            const result = await contract.methods.addMember(accounts[0], newName, '').send({ from: accounts[0] });
            document.getElementById('result').innerText = `Transaction successful! Transaction hash: ${result.transactionHash}`;
            displayMembers(); // Refresh member list after adding a new member
        } catch (error) {
            document.getElementById('result').innerText = `Error: ${error.message}`;
        }
    }
});

async function displayMembers() {
    const contract = new web3.eth.Contract(daoABI, contractAddress);
    const numOfMembers = await contract.methods.numOfMembers().call();
    const membersListContainer = document.getElementById('membersList');
    membersListContainer.innerHTML = ''; // Clear previous member list

    for (let i = 0; i < numOfMembers; i++) {
        const member = await contract.methods.membersList(i).call();
        const memberElement = document.createElement('div');
        memberElement.innerText = `Member: ${member.name}, Address: ${member.wallet}`;
        membersListContainer.appendChild(memberElement);
    }
}