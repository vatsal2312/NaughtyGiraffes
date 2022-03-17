// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract NaughtyGiraffes is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    uint256 private _publicStartTime = 1648823400; // Friday, April 1, 2022 2:30:00 PM GMT (Friday, April 1, 2022 10:30:00 AM GMT-04:00 DST)
    string private _tokenBaseURI;
    string private _tokenRevealedBaseURI; 
    bytes32 private merkleroot = 0;
    address private withdrawalWalletAddress;
    uint256 private totalNoOfMints = 0;

    mapping(address => uint256) public totalNoOfTokensMintedByAddress;

    event SetStartTime(uint256 _timestamp);

    // Pre Sale Attributes
    uint256 public maxMintPerAddressInPresale = 3;
    uint256 public preSalePrice = 0.05 ether;
    uint256 public maxPresaleSupply = 1000;
    
    // Early Bird Sale Attributes
    uint256 public maxMintPerAddressInEarlysale = 3;
    uint256 public earlySalePrice = 0.06 ether;
    uint256 public maxEarlysaleSupply = 3000;

    // Public Sale Attributes
    uint256 public maxMintPerAddressInPublicsale = 10;
    uint256 public publicSalePrice = 0.08 ether;
    uint256 public maxPublicsaleSupply = 10000;
   
    constructor() ERC721("Naughty Giraffes", "GIRAFFE") {
        _tokenBaseURI = "https://api.example.com/";
    }


    //Check if address is a #{Lazy Lions} or ${Smilesssvrs} NFT holder to be eligible for presale
    modifier isAddressOnWhitelist(bytes32[] memory _merkleproof) {
        if(block.timestamp >= _publicStartTime - 86400) {
            // Everyone can Mint
        }else if(block.timestamp >= (_publicStartTime - 172800)){
           require(MerkleProof.verify(
                    _merkleproof,
                    merkleroot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "Address is not on white list."
            );
        }else require(false,"Sale is not Start yet.");
        _;
    }

    //Check if presale is live
    modifier isLive() {
        require(block.timestamp >= (_publicStartTime - 172800), "Pulic sale hasn't started yet!");
        _;
    }

    //Update memory variables based on timestamp against three categories and mint accordingly.
    function mintSale(uint256 _numOfTokensToMint, bytes32[] calldata _merkleproof) 
        external 
        payable
        isLive
        isAddressOnWhitelist(_merkleproof)
    {

        uint256 maxMintPerAddress;
        uint256 mintPrice;
        uint256 maxMintsPerCategory;
        uint256 supply = totalNoOfMints;
        uint256 totalTokensMintedByAddress = totalNoOfTokensMintedByAddress[msg.sender];
   
        if(block.timestamp >= _publicStartTime) {
            maxMintPerAddress = maxMintPerAddressInPublicsale;
            mintPrice = publicSalePrice;
            maxMintsPerCategory = maxPublicsaleSupply;
        }else if(block.timestamp >= (_publicStartTime - 86400)){
            maxMintPerAddress = maxMintPerAddressInEarlysale;
            mintPrice = earlySalePrice;
            maxMintsPerCategory = maxEarlysaleSupply;
        }else if(block.timestamp >= (_publicStartTime - 172800)){
            maxMintPerAddress = maxMintPerAddressInPresale;
            mintPrice = preSalePrice;
            maxMintsPerCategory = maxPresaleSupply;
        }
        require(_numOfTokensToMint <= maxMintPerAddress, "Exceeds the number of token mints permitted for this category per transaction.");
        require(totalTokensMintedByAddress + _numOfTokensToMint <= maxMintPerAddress,"Exceeds the number of token mints available per account.");
        require(supply + _numOfTokensToMint <= maxMintsPerCategory, "Not enough tokens remaining to mint!");
        require(_numOfTokensToMint * mintPrice <= msg.value, "Incorrect eth amount sent to mint!");

        for (uint256 i; i < _numOfTokensToMint; i++) {
            _mint(msg.sender, supply += 1);
        }

        totalNoOfMints += _numOfTokensToMint;
        totalNoOfTokensMintedByAddress[msg.sender] = totalTokensMintedByAddress + _numOfTokensToMint;
    }

    //Set Merkle tree to enable whitelist.
    function setMerkleroot(bytes32 _merkleRoot) public onlyOwner {
       merkleroot = _merkleRoot;
    }

    function setStartTime(uint256 newTime) public onlyOwner  {
        _publicStartTime = newTime;
        emit SetStartTime(newTime);
    }

    function setMaxMintPerAddress(uint256[] memory _mintPerAddress) public onlyOwner {
        maxMintPerAddressInPresale = _mintPerAddress[0];
        maxMintPerAddressInEarlysale = _mintPerAddress[1];
        maxMintPerAddressInPublicsale = _mintPerAddress[2];
    }

    function setMintPrice(uint256[] memory _mintPrice) public onlyOwner {
        preSalePrice = _mintPrice[0];
        earlySalePrice = _mintPrice[1];
        publicSalePrice = _mintPrice[2];
    }

     function setMaxSupply(uint256[] memory _maxSupply) public onlyOwner {
        maxPresaleSupply = _maxSupply[0];
        maxEarlysaleSupply = _maxSupply[1];
        maxPublicsaleSupply = _maxSupply[2];
    }

    // Only a designated wallet address can withdraw
    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount,"Add correct eth amount to withdraw.");
        uint256 balance = address(this).balance;
        payable(withdrawalWalletAddress).transfer(balance);
    }

    function tokensInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        _tokenBaseURI = _uri;
    }

    function setRevealedBaseURI(string calldata _revealedBaseUri) external onlyOwner {
        _tokenRevealedBaseURI = _revealedBaseUri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return
            bytes(_tokenRevealedBaseURI).length > 0
                ? string(
                    abi.encodePacked(_tokenRevealedBaseURI, _tokenId.toString())
                )
                : _tokenBaseURI;
    }
}
