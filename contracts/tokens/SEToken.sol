// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IUniswapV2Pair.sol";
/**
🌀项目名称：SE
Ⓜ️发行机制：总量4亿枚
50% 全网𝐌𝐢𝐧𝐭
25% 永久𝐋𝐏池
25%上线销毁
❇️发行价格：𝟬.𝟬𝟬𝟭𝐔/枚
✳️铸造价格：4𝟬$/份=4𝟬𝟬𝟬𝟬枚

💹交易机制：买卖各5%
1%𝐍𝐅𝐓分红〈社区长分红〉
1%生态基金〈生态激励池〉
3% LP分红〈得𝐁𝐍𝐁永久分红〉(买卖5%税点的币全部销毁，但是BNB流入到相应的分红池)

Lp机制：
添加Lp税点1%给NFT持有者分红，撤Lp税点20%，其中10%的代币销毁，另外10%流入LP分红池，

当SE流通量只有200万枚时，取消所有税点停止销毁

🔯备注：社区长分红还是按32张NFT卡牌铸造

转账，卖，地址都留下0.2%(千分之2)，保持持币地址

DAPP预留一个Mint页面，以40油为基数Mint，不设上限只需要40的倍数即可

设定开盘时间，开盘滑点：1分钟，买卖30%，2～30分钟，买5%，卖30%，30～59分钟，买5%卖10；1小时后后正常税点。高税收入流入生态激励池

// 账号信息

SE$～Mint钱包地址（Mint的油进这个地址）
0x6Cd24A63947548fe6290Fe777B6A3419449Ea28F

SE$~生态基金池分红地址（买卖税点1%和上线高税收进入这个地址，单纯的存放不做合约）
0x1a08C6f79440656536c027Cb9ab0cB671Ce6c7Ad

SE$～NFT分红合约（买卖税点的1%和添加Lp税点1%进入这个地址，然后再实时分配给持有NFT的地址）
0x4c6F3f6606ae063DB221CD60eCB8C9F6d085C731

SE$～LP流动性分红合约（买卖税收的3%和撤Lp的10%进去这个地址，然后实时按权重分配给添加Lp的地址）
0x8b7D471e1496b04164baF6b4dc7d41a5de46Ff16

SE$～32张NFT接收地址（范师傅铸造出来的NFT放这个地址即可）0x1eF6E29cC8A97b96b02430465980996e05E51726
 */
contract SEToken is ERC20Capped, Ownable {

    event SEBought(address indexed buyer, uint256 times);

    uint256 public constant MaxSupply     = 400_000_000 *  10**18;
    uint256 public constant TotalMintable = MaxSupply / 2;  // 50% for mint
    uint256 public constant TotalBurnable = MaxSupply / 4;  // 25% for burn
    uint256 public constant FixedLpAmount = MaxSupply / 4;  // 25% for LP, owner holds it

    address public constant DeadAddress     = 0x000000000000000000000000000000000000dEaD;
    address public constant usdtReceiver    = 0x6Cd24A63947548fe6290Fe777B6A3419449Ea28F;
    address public constant nftShareAddress = 0x4c6F3f6606ae063DB221CD60eCB8C9F6d085C731;
    address public constant lpShareAddress  = 0x8b7D471e1496b04164baF6b4dc7d41a5de46Ff16;
    address public constant ecoFundAddress  = 0x1a08C6f79440656536c027Cb9ab0cB671Ce6c7Ad;

    uint256 public constant  MintAmount = 40000 * 10**18;  // 40000 SE for 40 USDT
    uint256 public immutable MintPrice;  // 40 USDT

    address public immutable router;
    address public immutable token0;

    uint256 public mintedAmount;
    address public usdtAddress;
    uint8   public immutable usdtDecimals;
    address public uniswapV2Pair;
    uint256 public startTimeForSwap;

    constructor(address _usdt, address _router, address _token0) ERC20Capped(MaxSupply) ERC20("SE Token", "SE") {
        require(_token0 < address(this), "Token0 small");

        usdtAddress = _usdt;
        router = _router;
        token0 = _token0;
        usdtDecimals = IERC20Metadata(_usdt).decimals();

        MintPrice = 40 * 10**usdtDecimals;

        _mint(DeadAddress, TotalBurnable);  // burn 25%
        _mint(msg.sender, FixedLpAmount);   // 25% for LP
    }

    function setStartTimeForSwap(uint256 _startTime) external onlyOwner {
        startTimeForSwap = _startTime;
    }

    function buy(uint256 times) external {
        require(times > 0, "SEToken: times must be greater than 0");
        require(times * MintAmount + mintedAmount <= TotalMintable, "SEToken: not enough SE to mint");

        uint256 usdtAmount = MintPrice * times;
        SafeERC20.safeTransferFrom(IERC20(usdtAddress), msg.sender, usdtReceiver, usdtAmount);

        mintedAmount += MintAmount * times;
        _mint(msg.sender, MintAmount * times);

        emit SEBought(msg.sender, times);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        execTransfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _spendAllowance(sender, msg.sender, amount);
        execTransfer(sender, recipient, amount);
        return true;
    }

    function execTransfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (tx.origin != owner()) {
            if (from == uniswapV2Pair || to == uniswapV2Pair) {
                require(block.timestamp >= startTimeForSwap, "SEToken: swap not started");
            }

            uint256 taxAmount = 0;
            if (from == uniswapV2Pair) {
                if (_isRemoveLiquidity()) { // for remove liquidity
                    taxAmount = amount * 20 / 100; // 20% for removing liquidity
                    shareRemoveLiquidtyTax(taxAmount);
                } else { // for buy SE
                    // 设定开盘时间，开盘滑点：1分钟，买卖30%，2～30分钟，买5%，卖30%，30～59分钟，买5%卖10；1小时后后正常税点。高税收入流入生态激励池
                    if (block.timestamp - startTimeForSwap < 1 minutes) {
                        taxAmount = amount * 30 / 100; // 30% for buying SE
                        highTaxRateShare(taxAmount);
                    } else if (block.timestamp - startTimeForSwap < 30 minutes) {
                        taxAmount = amount * 5 / 100; // 5% for buying SE
                        highTaxRateShare(taxAmount);
                    } else if (block.timestamp - startTimeForSwap < 59 minutes) {
                        taxAmount = amount * 5 / 100; // 5% for buying SE
                        highTaxRateShare(taxAmount);
                    } else {
                        taxAmount = amount * 5 / 100; // 5% for buying SE
                        shareBuySellTax(taxAmount);
                    }
                }
            }

            if (to == uniswapV2Pair) {
                if (_isAddLiquidity()) { // for add liquidity
                    taxAmount = amount * 1 / 100; // 1% for adding liquidity to lp
                    shareAddLiquidityTax(taxAmount);
                } else { // for sell SE
                // 设定开盘时间，开盘滑点：1分钟，买卖30%，2～30分钟，买5%，卖30%，30～59分钟，买5%卖10；1小时后后正常税点。高税收入流入生态激励池
                    if (block.timestamp - startTimeForSwap < 1 minutes) {
                        taxAmount = amount * 30 / 100; // 30% for selling SE
                        highTaxRateShare(taxAmount);
                    } else if (block.timestamp - startTimeForSwap < 30 minutes) {
                        taxAmount = amount * 30 / 100; // 30% for selling SE
                        highTaxRateShare(taxAmount);
                    } else if (block.timestamp - startTimeForSwap < 59 minutes) {
                        taxAmount = amount * 10 / 100; // 10% for selling SE
                        highTaxRateShare(taxAmount);
                    } else {
                        taxAmount = amount * 5 / 100; // 5% for normal selling SE
                        shareBuySellTax(taxAmount);
                    }
                }
            }

            amount -= taxAmount;
            amount = amount * 998 / 1000; // 0.2% for holding
        }

        super._transfer(from, to, amount);
    }

    function _isRemoveLiquidity() internal view returns(bool ldxDel){
        (uint r0, ,) = IUniswapV2Pair(address(uniswapV2Pair)).getReserves();
        uint bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));
        if( bal0 < r0){
            uint change0 = r0 - bal0;
            ldxDel = change0 > 1000;
        }
    }

	function _isAddLiquidity()internal view returns(bool ldxAdd){
        (uint r0, ,) = IUniswapV2Pair(address(uniswapV2Pair)).getReserves();
        uint bal = IERC20(token0).balanceOf(address(uniswapV2Pair));

        if( bal > r0){
            uint change0 = bal - r0;
            ldxAdd = change0 > 1000;
        }
    }

    function highTaxRateShare(uint256 taxAmount) internal {
        // 100%生态基金〈生态激励池〉
        super._transfer(msg.sender, ecoFundAddress, taxAmount);
    }

    function shareAddLiquidityTax(uint256 taxAmount) internal {
        // 添加Lp税点100%给NFT持有者分红，
        super._transfer(msg.sender, nftShareAddress, taxAmount);
    }

    function shareRemoveLiquidtyTax(uint256 taxAmount) internal {
        // 撤Lp总共收税点20%，其中10%的代币销毁，另外10%流入LP分红池，
        uint256 burnAmount = taxAmount * 50 / 100; // 10% for burn
        uint256 lpShareAmount = taxAmount * 50 / 100; // 10% for LP share

        super._transfer(msg.sender, DeadAddress, burnAmount);
        super._transfer(msg.sender, lpShareAddress, lpShareAmount);
    }

    function shareBuySellTax(uint256 taxAmount) internal {
        // 交易机制：买卖各5%
        // 1%𝐍𝐅𝐓分红〈社区长分红〉
        // 1%生态基金〈生态激励池〉
        // 3% LP分红〈得𝐁𝐍𝐁永久分红〉(买卖5%税点的币全部销毁，但是BNB流入到相应的分红池)
        uint256 nftShareAmount = taxAmount * 20 / 100; // 1% for NFT share
        uint256 ecoFundAmount = taxAmount * 20 / 100; // 1% for eco fund
        uint256 lpShareAmount = taxAmount * 60 / 100; // 3% for LP share

        super._transfer(msg.sender, nftShareAddress, nftShareAmount);
        super._transfer(msg.sender, ecoFundAddress, ecoFundAmount);
        super._transfer(msg.sender, lpShareAddress, lpShareAmount);
    }
}
