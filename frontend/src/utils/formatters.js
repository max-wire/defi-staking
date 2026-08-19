export function formatTokenAmount(value, options = {}) {
  const {
    maxDecimals = 2,
    minDecimals = 0,
  } = options;

  if (value === null || value === undefined || value === "") {
    return "0";
  }

  const number = Number(value);

  if (!Number.isFinite(number)) {
    return "0";
  }

  return new Intl.NumberFormat("en-US", {
    minimumFractionDigits: minDecimals,
    maximumFractionDigits: maxDecimals,
  }).format(number);
}