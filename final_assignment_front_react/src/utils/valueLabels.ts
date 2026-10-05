const FIELD_VALUE_LABELS: Record<string, Record<string, string>> = {
  vehicleType: {
    SmallCar: "小型汽车",
    LargeCar: "大型汽车",
    Motorcycle: "摩托车",
    Trailer: "挂车",
  },
  paymentMethod: {
    Cash: "现金",
    BankCard: "银行卡",
    Alipay: "支付宝",
    WeChat: "微信",
    BankTransfer: "转账",
    Other: "其他",
  },
};

export function getValueLabel(field: string, value: unknown): string {
  if (value == null || value === "") return "";
  const text = String(value);
  return FIELD_VALUE_LABELS[field]?.[text] ?? text;
}
