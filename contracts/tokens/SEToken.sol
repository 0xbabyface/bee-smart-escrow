// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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


// 判断添加还是撤除流动性:
// addLiquidity: msg.sender == router,  from = user, to = pair
// removeLiquidity:  msg.sender == router,  from = pair, to = user

// 判断交易:
//  sell: from = pair, to = user
//  buy:  from = user, to = pair
contract SEToken is ERC20Capped {

    uint256 constant MaxSupply = 400_000_000 *  10**18;
    address constant DeadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 constant TotalMintable = MaxSupply / 2;  // 50% for mint

    uint256 public mintAmount;
    address public usdtAddress;

    constructor(address _usdt) ERC20Capped(MaxSupply) ERC20("SE Token", "SE") {
        usdtAddress = _usdt;

        _mint(DeadAddress, MaxSupply / 4);  // burn 25%
    }

    function buy(uint256 times) external {

    }

}
