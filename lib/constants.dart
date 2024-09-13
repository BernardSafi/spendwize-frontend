const String baseUrl = "http://10.0.2.2:8000/api";

// Auth endpoints
const String loginEndpoint = "$baseUrl/login";
const String registerEndpoint = "$baseUrl/register";
const String walletBalanceEndpoint="$baseUrl/wallet";
const String savingsBalanceEndpoint = "$baseUrl/saving";
const String usernameEndpoint="$baseUrl/user/name";
const String addIncomeEndpoint="$baseUrl/transactions/income";
const String addExpenseEndpoint="$baseUrl/transactions/expense";
const String walletToSavingsUSD="$baseUrl/transfer/wallet-to-saving-usd";
const String savingsToWalletUSD="$baseUrl/transfer/saving-to-wallet-usd";
const String savingsToWalletLBP="$baseUrl/transfer/saving-to-wallet-lbp";
const String walletToSavingsLBP="$baseUrl/transfer/wallet-to-saving-lbp";

