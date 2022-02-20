// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Creature is ERC721Tradable {
    struct TokenData {
        bool physicalObjectClaimed;
        bool physicalObjectDelivered;
        string name;
    }
    bool public publicMintingStarted = false;
    mapping(uint256 => TokenData) private tokenData;
    mapping(string => uint256) public names;

    event PhysicalBadgeRequested(uint256 tokenId, bytes[32] requestHash);
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

    function mintTo(address _to, string memory _name) public onlyOwner override {
        uint256 currentTokenId = getNextTokenId();
        super.mintTo(_to);
        tokenData[currentTokenId] = TokenData({
            physicalObjectClaimed: false,
            physicalObjectDelivered: false
        });
        names[_name] = currentTokenId;
    }

    function setPublicMinting(_publicMintingAllowed) public onlyOwner {
        publicMintingStarted = _publicMintingAllowed;
    }

    function registerBadge(string memory _name, bytes32 _signature) public virtual {
        require(publicMintingStarted, "badge registration has not started");
        require(checkSignature(_name, _signature), "the name must be signed by the contract owner");
        require(names[_name] != 0, "name already registered");

        uint256 currentTokenId = getNextTokenId();
        super.mintTo(msgSender());
        tokenData[currentTokenId] = TokenData({
            physicalObjectClaimed: true,
            physicalObjectDelivered: true
        });
        names[_name] = currentTokenId;
    }

    function checkSignature(string _name, bytes32 _signature) private virtual returns (bool) {
        bytes32 messageHash = getMessageHash(_name);
        return recoverSigner(messageHash, _signature) == owner;
    }

    function recoverSigner(bytes32 _signedMessage, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_signedMessage, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (
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


    function registerPhysicalBadgeRequest(uint256 tokenId, bytes32 requestHash) public virtual {
        require(ownerOf(id) == _msgSender(), "Only the token owner can claim");
        require(!tokenData[tokenId].physicalObjectClaimed, "Already claimed");
        tokenData[tokenId].physicalObjectClaimed = true;
        emit PhysicalBadgeRequested(tokenId, requestHash);
    }

    function sendPhysicalBadge(uint256 tokenId) public virtual onlyOwner {
        tokenData[tokenId].physicalObjectClaimed = true;
        tokenData[tokenId].physicalObjectDelivered = true;
        emit PhysicalBadgeDelivered(tokenId);
    }
}
