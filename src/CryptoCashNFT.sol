// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId, int256 answer, uint256 startedAt,
        uint256 updatedAt, uint80 answeredInRound
    );
}

contract CryptoCashNFT is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public mintPrice = 0.001 ether;
    uint256 private _nextTokenId = 1;

    struct Coin {
        string name;
        string symbol;
        string color;
        address priceFeed;
    }

    Coin[] public coins;

    mapping(uint256 => uint256) public tokenCoin;
    mapping(uint256 => uint256) public tokenTimestamp;
    mapping(uint256 => string)  public tokenSerial;
    mapping(address => bool)    public hasFreeMinted;

    event Minted(address indexed to, uint256 tokenId, string symbol, string serial);

    constructor() ERC721("CryptoCash", "CCASH") Ownable(msg.sender) {
        _addCoin("Bitcoin",   "BTC",   "#F7931A", address(0));
        _addCoin("Ethereum",  "ETH",   "#627EEA", address(0));
        _addCoin("Tether",    "USDT",  "#26A17B", address(0));
        _addCoin("BNB",       "BNB",   "#F3BA2F", address(0));
        _addCoin("Solana",    "SOL",   "#9945FF", address(0));
        _addCoin("XRP",       "XRP",   "#00AAE4", address(0));
        _addCoin("USD Coin",  "USDC",  "#2775CA", address(0));
        _addCoin("Dogecoin",  "DOGE",  "#C2A633", address(0));
        _addCoin("Cardano",   "ADA",   "#0033AD", address(0));
        _addCoin("Avalanche", "AVAX",  "#E84142", address(0));
        _addCoin("Polkadot",  "DOT",   "#E6007A", address(0));
        _addCoin("Chainlink", "LINK",  "#375BD2", address(0));
        _addCoin("Polygon",   "MATIC", "#8247E5", address(0));
        _addCoin("Litecoin",  "LTC",   "#BFBBBB", address(0));
        _addCoin("Shiba Inu", "SHIB",  "#FFA409", address(0));
        _addCoin("Uniswap",   "UNI",   "#FF007A", address(0));
        _addCoin("Stellar",   "XLM",   "#7D00FF", address(0));
        _addCoin("Monero",    "XMR",   "#FF6600", address(0));
        _addCoin("Tron",      "TRX",   "#EF0027", address(0));
        _addCoin("Cosmos",    "ATOM",  "#6F4E7C", address(0));
    }

    function _addCoin(string memory name, string memory symbol, string memory color, address feed) internal {
        coins.push(Coin(name, symbol, color, feed));
    }

    function mint() external payable {
        require(msg.value >= mintPrice, "Insufficient payment");
        _mintToken(msg.sender);
    }

    function firstFreeMint() external {
        require(!hasFreeMinted[msg.sender], "Already used free mint");
        hasFreeMinted[msg.sender] = true;
        _mintToken(msg.sender);
    }

    function freeMint(address to) external onlyOwner {
        _mintToken(to);
    }

    function airdrop(address[] calldata recipients) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _mintToken(recipients[i]);
        }
    }

    function _mintToken(address to) internal {
        uint256 tokenId = _nextTokenId++;
        uint256 coinIndex = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, to))) % coins.length;
        string memory serial = _generateSerial(tokenId, block.timestamp);
        tokenCoin[tokenId] = coinIndex;
        tokenTimestamp[tokenId] = block.timestamp;
        tokenSerial[tokenId] = serial;
        _mint(to, tokenId);
        emit Minted(to, tokenId, coins[coinIndex].symbol, serial);
    }

    function _generateSerial(uint256 tokenId, uint256 ts) internal pure returns (string memory) {
        bytes memory chars = "0123456789ABCDEFGHJKLMNPQRSTUVWX";
        bytes memory serial = new bytes(19);
        uint256 seed = uint256(keccak256(abi.encodePacked(tokenId, ts)));
        uint256 pos = 0;
        for (uint256 i = 0; i < 16; i++) {
            serial[pos++] = chars[seed % chars.length];
            seed >>= 4;
            if ((i + 1) % 4 == 0 && i < 15) serial[pos++] = '-';
        }
        return string(serial);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        uint256 ci = tokenCoin[tokenId];
        Coin memory coin = coins[ci];

        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="300" viewBox="0 0 600 300">',
            '<rect width="600" height="300" rx="20" fill="#0a0a0a" stroke="', coin.color, '" stroke-width="2.5"/>',
            '<rect x="9" y="9" width="582" height="282" rx="14" fill="none" stroke="', coin.color, '" stroke-width="1" opacity="0.3"/>',
            '<circle cx="150" cy="150" r="85" fill="', coin.color, '" opacity="0.12"/>',
            '<circle cx="150" cy="150" r="85" fill="none" stroke="', coin.color, '" stroke-width="2.5"/>',
            '<text x="150" y="165" text-anchor="middle" font-family="monospace" font-size="42" font-weight="bold" fill="', coin.color, '">', coin.symbol, '</text>',
            '<text x="390" y="55" text-anchor="middle" font-family="monospace" font-size="20" font-weight="bold" fill="white" letter-spacing="5">CRYPTOCASH</text>',
            '<text x="290" y="105" font-family="monospace" font-size="9" fill="#39FF14" letter-spacing="2">SERIAL NUMBER</text>',
            '<text x="290" y="128" font-family="monospace" font-size="16" font-weight="bold" fill="#39FF14" letter-spacing="2">', tokenSerial[tokenId], '</text>',
            '<text x="290" y="162" font-family="monospace" font-size="9" fill="', coin.color, '" letter-spacing="2">TOKEN ID</text>',
            '<text x="290" y="182" font-family="monospace" font-size="18" font-weight="bold" fill="', coin.color, '">#', tokenId.toString(), '</text>',
            '<text x="290" y="215" font-family="monospace" font-size="9" fill="#39FF14" letter-spacing="2">MINTED</text>',
            '<text x="290" y="232" font-family="monospace" font-size="11" fill="#39FF14">', tokenTimestamp[tokenId].toString(), '</text>',
            '<rect x="430" y="262" width="145" height="24" rx="6" fill="', coin.color, '" opacity="0.15" stroke="', coin.color, '" stroke-width="1"/>',
            '<text x="502" y="278" text-anchor="middle" font-family="monospace" font-size="10" fill="', coin.color, '" letter-spacing="3">MONAD ERC-721</text>',
            '</svg>'
        ));

        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name":"CryptoCash #', tokenId.toString(), ' - ', coin.symbol, '",',
            '"description":"On-chain crypto banknote NFT with unique serial and timestamp.",',
            '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '",',
            '"attributes":[',
            '{"trait_type":"Coin","value":"', coin.name, '"},',
            '{"trait_type":"Symbol","value":"', coin.symbol, '"},',
            '{"trait_type":"Serial","value":"', tokenSerial[tokenId], '"},',
            '{"trait_type":"Network","value":"Monad"}',
            ']}'
        ))));

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function setMintPrice(uint256 p) external onlyOwner { mintPrice = p; }
    function updatePriceFeed(uint256 coinIndex, address feed) external onlyOwner { coins[coinIndex].priceFeed = feed; }
    function withdraw() external onlyOwner { payable(owner()).transfer(address(this).balance); }

    function _update(address to, uint256 tokenId, address auth)
        internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }
    function _increaseBalance(address account, uint128 value)
        internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }
    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
