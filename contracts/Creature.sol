// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Creature is ERC721Tradable {
    enum ClaimStatus { CLAIMABLE, CLAIM_REQUESTED, DELIVERED, UNCLAIMABLE }
    bool public publicMintingStarted = false;
    mapping(uint256 => ClaimStatus) private claimStatuses;
    mapping(string => uint256) public names;

    event PhysicalBadgeRequested(uint256 tokenId, bytes32 requestHash);
    event PhysicalBadgeDelivered(uint256 tokenId);

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("LivinTheMeme", "LTM", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://creatures-api.opensea.io/api/creature/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://creatures-api.opensea.io/contract/opensea-creatures";
    }

    function mintPremiumBadge(address _to, string memory _name) public onlyOwner {
        uint256 tokenId = _mintBadge(_to, _name);
        claimStatuses[tokenId] = ClaimStatus.CLAIMABLE;
    }

    function registerBadge(address _to, string memory _name, bytes memory _signature) public virtual {
        require(publicMintingStarted, "badge registration has not started");
        require(checkSignature(_name, _signature), "the name must be signed by the contract owner");
        uint256 tokenId = _mintBadge(_to, _name);
        claimStatuses[tokenId] = ClaimStatus.UNCLAIMABLE;
    }

    function _mintBadge(address _to, string memory _name) private returns (uint256 tokenId){
        require(names[_name] == 0, "Name must be unique");
        uint256 currentTokenId = getNextTokenId();
        super.mintTo(_to);
        names[_name] = currentTokenId;
        return currentTokenId;
    }

    function mintTo(address _to) public override onlyOwner {
        revert('token minting requires a unique name');
    }

    function setPublicMinting(bool _publicMintingAllowed) public onlyOwner {
        publicMintingStarted = _publicMintingAllowed;
    }

    function checkSignature(string memory _name, bytes memory _signature) private returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(_name));
        return recoverSigner(messageHash, _signature) == owner();
    }

    function recoverSigner(bytes32 _signedMessage, bytes memory _signature) private returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_signedMessage, v, r, s);
    }

    function splitSignature(bytes memory sig) private returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }


    function registerPhysicalBadgeRequest(uint256 tokenId, bytes32 requestHash) public {
        require(ownerOf(tokenId) == _msgSender(), "Only the token owner can claim");
        require(claimStatuses[tokenId] == ClaimStatus.CLAIMABLE, "Already claimed");
        claimStatuses[tokenId] = ClaimStatus.CLAIM_REQUESTED;
        emit PhysicalBadgeRequested(tokenId, requestHash);
    }

    function sendPhysicalBadge(uint256 tokenId) public onlyOwner {
        claimStatuses[tokenId] = ClaimStatus.DELIVERED;
        emit PhysicalBadgeDelivered(tokenId);
    }
}
