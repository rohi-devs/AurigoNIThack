// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ProcurementSystem is Ownable, ReentrancyGuard {
    // Constructor initialization
    constructor() Ownable(msg.sender) {}

    struct Tender {
        address company;
        string material;
        uint quantity;
        uint deadline;
        uint maxBudget;
        bool isOpen;
        address selectedVendor;
        uint escrowAmount;
    }

    struct Bid {
        address vendor;
        uint cost;
        string qualityProof;
        bool isActive;
    }

    struct VendorInfo {
        uint reputationScore;
        uint totalRatings;
        uint sumRatings;
        uint[] pastTenders;
    }

    uint public tenderCount;
    mapping(uint => Tender) public tenders;
    mapping(uint => Bid[]) public bids;
    mapping(address => VendorInfo) public vendors;
    mapping(address => mapping(uint => bool)) public hasRated;

    event TenderCreated(uint tenderId, address company, string material);
    event BidSubmitted(uint tenderId, address vendor, uint cost);
    event VendorSelected(uint tenderId, address vendor, uint amount);
    event PaymentReleased(uint tenderId, address vendor, uint amount);
    event VendorRated(address vendor, address company, uint rating);

    modifier onlyCompany(uint _tenderId) {
        require(msg.sender == tenders[_tenderId].company, "Not authorized");
        _;
    }

    function createTender(
        string memory _material,
        uint _quantity,
        uint _duration,
        uint _maxBudget
    ) external payable {
        require(msg.value == _maxBudget, "Incorrect escrow amount");
        
        tenderCount++;
        tenders[tenderCount] = Tender({
            company: msg.sender,
            material: _material,
            quantity: _quantity,
            deadline: block.timestamp + _duration,
            maxBudget: _maxBudget,
            isOpen: true,
            selectedVendor: address(0),
            escrowAmount: msg.value
        });

        emit TenderCreated(tenderCount, msg.sender, _material);
    }

    function submitBid(
        uint _tenderId,
        uint _cost,
        string memory _qualityProof
    ) external {
        Tender storage tender = tenders[_tenderId];
        require(tender.isOpen, "Tender closed");
        require(block.timestamp < tender.deadline, "Deadline passed");
        require(_cost <= tender.maxBudget, "Bid exceeds budget");

        bids[_tenderId].push(Bid({
            vendor: msg.sender,
            cost: _cost,
            qualityProof: _qualityProof,
            isActive: true
        }));

        emit BidSubmitted(_tenderId, msg.sender, _cost);
    }

    function calculateScore(uint _tenderId, uint _bidIndex) public view returns (uint) {
        Bid memory bid = bids[_tenderId][_bidIndex];
        VendorInfo memory vendor = vendors[bid.vendor];
        
        uint costScore = (tenders[_tenderId].maxBudget - bid.cost) * 40 / tenders[_tenderId].maxBudget;
        uint qualityScore = bytes(bid.qualityProof).length > 0 ? 35 : 0;
        uint reputationScore = vendor.reputationScore * 25 / 5; // Normalize 5-star to 25 points
        
        return costScore + qualityScore + reputationScore;
    }

    function selectVendor(uint _tenderId, uint _bidIndex) external onlyCompany(_tenderId) nonReentrant {
        Tender storage tender = tenders[_tenderId];
        require(tender.isOpen, "Tender closed");
        require(block.timestamp >= tender.deadline, "Deadline not reached");
        require(_bidIndex < bids[_tenderId].length, "Invalid bid index");

        Bid storage bid = bids[_tenderId][_bidIndex];
        require(bid.isActive, "Invalid bid");

        tender.selectedVendor = bid.vendor;
        tender.isOpen = false;
        tender.escrowAmount = bid.cost;

        if (tender.maxBudget > bid.cost) {
            payable(tender.company).transfer(tender.maxBudget - bid.cost);
        }

        vendors[bid.vendor].pastTenders.push(_tenderId);
        emit VendorSelected(_tenderId, bid.vendor, bid.cost);
    }

    function releasePayment(uint _tenderId) external onlyCompany(_tenderId) nonReentrant {
        Tender storage tender = tenders[_tenderId];
        require(!tender.isOpen, "Tender not completed");
        require(tender.escrowAmount > 0, "Escrow empty");

        uint amount = tender.escrowAmount;
        tender.escrowAmount = 0;
        payable(tender.selectedVendor).transfer(amount);

        emit PaymentReleased(_tenderId, tender.selectedVendor, amount);
    }

    function rateVendor(address _vendor, uint _tenderId, uint _rating) external {
        Tender storage tender = tenders[_tenderId];
        require(tender.selectedVendor == _vendor, "Vendor not selected");
        require(msg.sender == tender.company, "Not authorized");
        require(!hasRated[msg.sender][_tenderId], "Already rated");
        require(_rating >= 1 && _rating <= 5, "Invalid rating");

        hasRated[msg.sender][_tenderId] = true;
        VendorInfo storage vendor = vendors[_vendor];
        
        vendor.sumRatings += _rating;
        vendor.totalRatings++;
        vendor.reputationScore = vendor.sumRatings / vendor.totalRatings;

        emit VendorRated(_vendor, msg.sender, _rating);
    }

    function getTopBidIndex(uint _tenderId) public view returns (uint) {
        uint highestScore;
        uint winningIndex;
        
        for(uint i = 0; i < bids[_tenderId].length; i++) {
            uint score = calculateScore(_tenderId, i);
            if(score > highestScore) {
                highestScore = score;
                winningIndex = i;
            }
        }
        return winningIndex;
    }
}