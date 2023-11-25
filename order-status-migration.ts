enum Status {
  UNKNOWN,       // occupate the default status
  NORMAL,        // normal status
  ADJUSTED,      // buyer adjuste amount
  CONFIRMED,     // seller confirmed
  CANCELLED,     // buyer adjust amount to 0
  SELLERDISPUTE, // seller dispute
  BUYERDISPUTE,  // buyer dispute
  LOCKED,        // both buyer and seller disputed
  SELLERWIN,     // community decide seller win
  BUYERWIN       // community decide buyer win
}

function orderStatusMsg(order: {currStatus: Status, prevStatus: Status}) {
  if (order.currStatus == Status.NORMAL && order.prevStatus == Status.UNKNOWN) {
    return "新建订单"
  }
  else if (order.currStatus == Status.ADJUSTED && order.prevStatus == Status.NORMAL) {
    return "订单数量调整"
  }
  else if (order.currStatus == Status.CANCELLED && order.prevStatus == Status.NORMAL) {
    return "订单取消"
  }
  else if (order.currStatus == Status.CONFIRMED && (order.prevStatus == Status.NORMAL || order.prevStatus == Status.ADJUSTED)) {
    return "订单正常完成"
  }
  else if (order.currStatus == Status.SELLERDISPUTE && (order.prevStatus == Status.NORMAL || order.prevStatus == Status.ADJUSTED)) {
    return "卖家发起仲裁"
  }
  else if (order.currStatus == Status.BUYERDISPUTE && (order.prevStatus == Status.NORMAL || order.prevStatus == Status.ADJUSTED)) {
    return "买家发起仲裁"
  }
  else if (order.currStatus == Status.NORMAL && order.prevStatus == Status.SELLERDISPUTE) {
    return "卖家撤回仲裁"
  }
  else if (order.currStatus == Status.NORMAL && order.prevStatus == Status.BUYERDISPUTE) {
    return "买家撤回仲裁"
  }
  else if (order.currStatus == Status.LOCKED && order.prevStatus == Status.SELLERDISPUTE) {
    return "卖家发起仲裁, 买家也发起仲裁, 订单锁定, 社区介入"
  }
  else if (order.currStatus == Status.LOCKED && order.prevStatus == Status.BUYERDISPUTE) {
    return "买家发起仲裁, 卖家也发起仲裁, 订单锁定, 社区介入"
  }
  else if (order.currStatus == Status.SELLERWIN && order.prevStatus == Status.LOCKED) {
    return "订单锁定, 社区介入判卖家胜"
  }
  else if (order.currStatus == Status.BUYERWIN && order.prevStatus == Status.LOCKED) {
    return "订单锁定, 社区介入判买家胜"
  }
  else if (order.currStatus == Status.NORMAL && order.prevStatus == Status.LOCKED) {
    return "订单锁定, 社区介入判双方平手, 订单回到初始状态"
  }
  else if (order.currStatus == Status.CONFIRMED && order.prevStatus == Status.SELLERDISPUTE) {
    return "卖家发起仲裁, 买家无响应, 订单完成"
  }
  else if (order.currStatus == Status.CONFIRMED && order.prevStatus == Status.BUYERDISPUTE) {
    return "买家发起仲裁, 卖家无响应, 订单完成"
  } else {
    return "订单异常"
  }
}