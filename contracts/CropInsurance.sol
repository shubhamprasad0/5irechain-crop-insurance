//SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";


contract CropInsurance {
    uint moneyUnit = 0.01 ether;
    address public insurer;
    uint thresholdWeatherIndex;
    uint currentWeatherIndex;
    uint totalPayableAmount;
    bool withdrawnByInsurer;
    uint startTime;
    uint insurancePeriodEndTime;
    uint cropSeasonEndTime;

    mapping (address => PolicyHolder) public policyHolders;
    address[] private policyHolderAddresses;

    enum PolicyPlan {
        BASIC,
        PRO,
        GOLD,
        PLATINUM
    }

    struct PolicyDetail {
        uint sumAssured;
        uint premiumAmount;
        uint numInstallments;
    }

    mapping (PolicyPlan => PolicyDetail) public plans;

    struct PolicyHolder {
        string name;
        uint age;
        address accountAddress;
        PolicyPlan policyPlan;
        uint numInstallmentsLeft;
        bool claimPaid;
    }

    // modifiers
    modifier onlyInsurer() {
        require(msg.sender == insurer, "Only insurer can call this function.");
        _;
    }

    modifier notInsurer() {
        require(msg.sender != insurer, "The insurer cannot take a policy.");
        _;
    }

    modifier checkRegistrationPremiumAmount(PolicyPlan policyPlan) {
        require(msg.value == plans[policyPlan].premiumAmount, "Please pay the required premium amount.");
        _;
    }

    modifier checkInstallmentPremiumAmount() {
        PolicyPlan policyPlan = policyHolders[msg.sender].policyPlan;
        require(msg.value == plans[policyPlan].premiumAmount, "Please pay the required premium amount.");
        _;
    }

    modifier isRegistered() {
        require(policyHolders[msg.sender].accountAddress == msg.sender, "You must register first to pay installments.");
        _;
    }

    modifier cropSeasonEnded() {
        require(block.timestamp > cropSeasonEndTime, "Can only perform this operation after the crop season has ended.");
        _;
    }

    modifier inInsurancePeriod() {
        require(block.timestamp <= insurancePeriodEndTime, "Can only perform this operation within the insurance period.");
        _;
    }

    // functions
    constructor() {
        plans[PolicyPlan.BASIC] = PolicyDetail({sumAssured: 10 * moneyUnit, premiumAmount: 1 * moneyUnit, numInstallments: 3});
        plans[PolicyPlan.PRO] = PolicyDetail({sumAssured: 20 * moneyUnit, premiumAmount: 2 * moneyUnit, numInstallments: 3});
        plans[PolicyPlan.GOLD] = PolicyDetail({sumAssured: 30 * moneyUnit, premiumAmount: 3 * moneyUnit, numInstallments: 3});
        plans[PolicyPlan.PLATINUM] = PolicyDetail({sumAssured: 40 * moneyUnit, premiumAmount: 4 * moneyUnit, numInstallments: 3});
    }

    function startInsurancePeriod(uint _thresholdWeatherIndex, uint _insurancePeriodDuration, uint _cropSeasonDuration) public payable {
        require(2 * _insurancePeriodDuration < _cropSeasonDuration, "cropSeasonDuration must be greater than 2 * insurancePeriodDuration.");
        require(msg.value >= 100 * moneyUnit, "Deposit 100 money units to create the insurance policies.");
        insurer = msg.sender;

        thresholdWeatherIndex = _thresholdWeatherIndex;
        totalPayableAmount = 0;
        withdrawnByInsurer = false;

        startTime = block.timestamp;
        insurancePeriodEndTime = startTime + _insurancePeriodDuration;
        cropSeasonEndTime = startTime + _cropSeasonDuration;
    }

    function registerUser(string memory name, uint age, PolicyPlan policyPlan) public payable notInsurer checkRegistrationPremiumAmount(policyPlan) inInsurancePeriod {
        PolicyHolder memory policyHolder = PolicyHolder({
            name: name, 
            age: age, 
            accountAddress: msg.sender,
            policyPlan: policyPlan,
            numInstallmentsLeft: plans[policyPlan].numInstallments - 1,
            claimPaid: false
        });
        policyHolders[msg.sender] = policyHolder;
        policyHolderAddresses.push(msg.sender);
    }

    function payInstallment() public payable isRegistered notInsurer checkInstallmentPremiumAmount {
        require(policyHolders[msg.sender].numInstallmentsLeft > 0, "All of your installments are already paid");
        policyHolders[msg.sender].numInstallmentsLeft--;
    }

    function setCurrentWeatherIndex(uint weatherIndex) public onlyInsurer {
        currentWeatherIndex = weatherIndex;
    }

    function payClaim(address policyHolderAddress) public payable onlyInsurer {
        require(currentWeatherIndex > thresholdWeatherIndex, "The current weather index has not crossed the threshold weather index yet.");
        require(policyHolders[policyHolderAddress].accountAddress == policyHolderAddress, "This user has not registered for insurance.");
        PolicyHolder storage policyHolder = policyHolders[policyHolderAddress];
        require(!policyHolder.claimPaid, "The claim amount has already been paid to the policy holder's account.");

        if (payable(policyHolder.accountAddress).send(plans[policyHolder.policyPlan].sumAssured)) {
            policyHolder.claimPaid = true;
        }
    }

    function withdrawInsurerAmount() public payable onlyInsurer cropSeasonEnded {
        require(address(this).balance > 0, "No balance left to withdraw.");
        payable(insurer).transfer(address(this).balance);
    }
}