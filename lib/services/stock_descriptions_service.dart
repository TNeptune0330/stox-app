class StockDescriptionsService {
  static final Map<String, String> _stockDescriptions = {
    // FAANG + Major Tech
    'AAPL': 'Apple Inc. designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide. The company serves consumers, and small and mid-sized businesses; and the education, enterprise, and government markets.',
    'GOOGL': 'Alphabet Inc. provides various products and platforms in the United States, Europe, the Middle East, Africa, the Asia-Pacific, Canada, and Latin America. It operates through Google Services, Google Cloud, and Other Bets segments.',
    'GOOG': 'Alphabet Inc. provides various products and platforms in the United States, Europe, the Middle East, Africa, the Asia-Pacific, Canada, and Latin America. It operates through Google Services, Google Cloud, and Other Bets segments.',
    'MSFT': 'Microsoft Corporation develops, licenses, and supports software, services, devices, and solutions worldwide. Its Productivity and Business Processes segment offers Office, Exchange, SharePoint, Microsoft Teams, Office 365 Security and Compliance, and Skype for Business.',
    'AMZN': 'Amazon.com, Inc. engages in the retail sale of consumer products and subscriptions in North America and internationally. The company operates through three segments: North America, International, and Amazon Web Services (AWS).',
    'META': 'Meta Platforms, Inc. develops products that enable people to connect and share with friends and family through mobile devices, personal computers, virtual reality headsets, wearables, and in-home devices worldwide.',
    'TSLA': 'Tesla, Inc. designs, develops, manufactures, leases, and sells electric vehicles, and energy generation and storage systems in the United States, China, and internationally. The company operates in two segments, Automotive, and Energy Generation and Storage.',
    'NVDA': 'NVIDIA Corporation provides graphics, and compute and networking solutions in the United States, Taiwan, China, Hong Kong, and internationally. The company operates in two segments, Graphics and Compute & Networking.',
    'NFLX': 'Netflix, Inc. provides entertainment services. It offers TV series, documentaries, feature films, and mobile games across a wide variety of genres and languages to members in over 190 countries.',
    
    // Other Major Stocks
    'ORCL': 'Oracle Corporation provides products and services that address enterprise information technology environments worldwide. Its Oracle cloud software as a service offering include various cloud software applications.',
    'CRM': 'Salesforce, Inc. provides Customer Relationship Management (CRM) technology that brings companies and customers together worldwide. Its Customer 360 platform provides a single source of truth.',
    'ADBE': 'Adobe Inc. operates as a diversified software company worldwide. It operates through three segments Digital Media, Digital Experience, and Publishing and Advertising.',
    'NOW': 'ServiceNow, Inc. provides enterprise cloud computing solutions that defines, structures, consolidates, manages, and automates services for enterprises worldwide.',
    'INTU': 'Intuit Inc. provides financial management and compliance solutions for consumers, small businesses, employers, and accounting professionals in the United States, Canada, and internationally.',
    'AMD': 'Advanced Micro Devices, Inc. operates as a semiconductor company worldwide. It operates in two segments, Computing and Graphics; and Enterprise, Embedded and Semi-Custom.',
    'QCOM': 'QUALCOMM Incorporated engages in the development and commercialization of foundational technologies for the wireless industry worldwide. It operates through three segments: QCT, QTL, and QSI.',
    'AVGO': 'Broadcom Inc. designs, develops, and supplies various semiconductor devices with a focus on complex digital and mixed signal complementary metal oxide semiconductor based devices and analog III-V based products worldwide.',
    'TXN': 'Texas Instruments Incorporated designs, manufactures, and sells semiconductors to electronics designers and manufacturers worldwide. It operates in two segments, Analog and Embedded Processing.',
    'INTC': 'Intel Corporation designs, manufactures, and sells computer components and related products for business and consumer markets worldwide. It operates through CCG, DCG, IOTG, Mobileye, NSG, PSG, and All Other segments.',
    'CSCO': 'Cisco Systems, Inc. designs, manufactures, and sells Internet Protocol based networking and other products related to the communications and information technology industry in the Americas, Europe, the Middle East, Africa, the Asia Pacific, Japan, and China.',
    
    // Financial Stocks
    'JPM': 'JPMorgan Chase & Co. operates as a financial services company worldwide. It operates through four segments: Consumer & Community Banking (CCB), Corporate & Investment Bank (CIB), Commercial Banking (CB), and Asset & Wealth Management (AWM).',
    'BAC': 'Bank of America Corporation, through its subsidiaries, provides banking and financial products and services for individual consumers, small and middle-market businesses, institutional investors, large corporations, and governments worldwide.',
    'WFC': 'Wells Fargo & Company, a diversified financial services company, provides banking, investment, mortgage, and consumer and commercial finance products and services in the United States and internationally.',
    'GS': 'The Goldman Sachs Group, Inc., a financial institution, provides a range of financial services for corporations, financial institutions, governments, and individuals worldwide.',
    'MS': 'Morgan Stanley, a financial holding company, provides various financial products and services to corporations, governments, financial institutions, and individuals in the Americas, Europe, the Middle East, Africa, and Asia.',
    'C': 'Citigroup Inc., a diversified financial services holding company, provides various financial products and services to consumers, corporations, governments, and institutions in North America, Latin America, Asia, Europe, the Middle East, and Africa.',
    'AXP': 'American Express Company, together with its subsidiaries, provides charge and credit payment card products, and travel-related services worldwide. The company operates through three segments: Global Consumer Services Group, Global Commercial Services, and Global Merchant and Network Services.',
    'V': 'Visa Inc. operates as a payments technology company worldwide. The company facilitates digital payments among consumers, merchants, financial institutions, businesses, strategic partners, and government entities.',
    'MA': 'Mastercard Incorporated, a technology company, provides transaction processing and other payment-related products and services in the United States and internationally.',
    'PYPL': 'PayPal Holdings, Inc. operates a technology platform that enables digital payments on behalf of merchants and consumers worldwide. It provides payment solutions under the PayPal, PayPal Credit, Braintree, Venmo, Xoom, Zettle, Hyperwallet, Honey, and Paidy names.',
    
    // ETFs
    'SPY': 'SPDR S&P 500 ETF Trust seeks to provide investment results that, before expenses, correspond generally to the price and yield performance of the S&P 500 Index.',
    'QQQ': 'Invesco QQQ Trust is based on the Nasdaq-100 Index. The Fund will, under most circumstances, consist of all of stocks in the Index. The Index includes 100 of the largest domestic and international non-financial companies listed on the Nasdaq Stock Market.',
    'IWM': 'iShares Russell 2000 ETF seeks to track the investment results of the Russell 2000 Index, which measures the performance of the small-capitalization sector of the U.S. equity market.',
    'DIA': 'SPDR Dow Jones Industrial Average ETF Trust seeks to provide investment results that, before expenses, correspond generally to the price and yield performance of the Dow Jones Industrial Average.',
    'VOO': 'Vanguard S&P 500 ETF seeks to track the performance of the Standard & Poor\'s 500 Index that measures the investment return of large-capitalization stocks.',
    'VTI': 'Vanguard Total Stock Market ETF seeks to track the performance of the CRSP US Total Market Index that measures the investment return of the overall stock market.',
    'SOXL': 'Direxion Daily Semiconductor Bull 3X Shares seeks daily investment results, before fees and expenses, of 300% of the performance of the PHLX Semiconductor Sector Index.',
    'SOXX': 'iShares Semiconductor ETF seeks to track the investment results of the NYSE Semiconductor Index composed of U.S. equities in the semiconductor sector.',
    'ARKK': 'ARK Innovation ETF is an actively managed exchange-traded fund that seeks long-term growth of capital by investing in companies that are relevant to the investment theme of disruptive innovation.',
    'GLD': 'SPDR Gold Shares is designed to track the price of gold bullion in the over-the-counter market, and provide investors with a means of participating in the gold market without the necessity of taking physical delivery of gold.',
    'TLT': 'iShares 20+ Year Treasury Bond ETF seeks to track the investment results of the ICE U.S. Treasury 20+ Year Bond Index composed of U.S. Treasury bonds with remaining maturities greater than twenty years.',
    
    // Cryptocurrencies
    'BTC-USD': 'Bitcoin is a decentralized digital currency, without a central bank or single administrator, that can be sent from user to user on the peer-to-peer bitcoin network without the need for intermediaries.',
    'ETH-USD': 'Ethereum is a decentralized, open-source blockchain with smart contract functionality. Ether is the native cryptocurrency of the platform and the second-largest cryptocurrency by market capitalization.',
    'BNB-USD': 'Binance Coin is a utility cryptocurrency that operates as a payment method for the fees associated with trading on the Binance Exchange. It is also used as the native token of the Binance Smart Chain.',
    'ADA-USD': 'Cardano is a blockchain platform for changemakers, innovators, and visionaries, with the tools and technologies required to create good for the many, as well as the few, and bring about positive global change.',
    'SOL-USD': 'Solana is a decentralized blockchain built to enable scalable, user-friendly apps for the world. Solana ensures composability between ecosystem projects by maintaining a single global state as the network scales.',
    'DOT-USD': 'Polkadot is a protocol that allows independent blockchains to exchange information. Polkadot is an open-source sharded multichain protocol that connects and secures a network of specialized blockchains.',
    'DOGE-USD': 'Dogecoin is a cryptocurrency created as a joke in early 2013. It is based on the popular Doge Internet meme and features a Shiba Inu on its logo.',
    'AVAX-USD': 'Avalanche is a layer one blockchain that functions as a platform for decentralized applications and custom blockchain networks. It is one of Ethereum\'s rivals, aiming to unseat Ethereum as the most popular blockchain for smart contracts.',
    'MATIC-USD': 'Polygon is a decentralized platform that is used to create interconnected blockchain networks. It seeks to create a multi-chain ecosystem of Ethereum-compatible blockchains.',
    
    // Popular Individual Stocks
    'UBER': 'Uber Technologies, Inc. operates as a technology platform for people and things mobility. The company operates through three segments: Mobility, Delivery, and Freight.',
    'LYFT': 'Lyft, Inc. operates a peer-to-peer marketplace for on-demand ridesharing in the United States and Canada. The company operates multimodal transportation networks that offer riders personalized and on-demand access to various mobility options.',
    'SNAP': 'Snap Inc. operates as a camera company in North America, Europe, and internationally. The company offers Snapchat, a camera application with various functionalities, such as Camera, Communication, Snap Map, Stories, and Spotlight.',
    'PINS': 'Pinterest, Inc. operates as a visual discovery engine in the United States and internationally. The company\'s engine allows people to find inspiration for their lives, including recipes, style and home inspiration, DIY, and others.',
    'SQ': 'Block, Inc. provides payment and point-of-sale solutions in the United States and internationally. The company operates through two segments, Square and Cash App.',
    'SHOP': 'Shopify Inc., a commerce company, provides a commerce platform and services in Canada, the United States, the United Kingdom, Australia, Latin America, and internationally.',
    'SPOT': 'Spotify Technology S.A., together with its subsidiaries, provides audio streaming services worldwide. It operates through two segments, Premium and Ad-Supported.',
    'ZOOM': 'Zoom Video Communications, Inc. provides unified communications platform in the Americas, the Asia Pacific, Europe, the Middle East, and Africa. The company offers Zoom Meetings that offers HD video, voice, chat, and content sharing.',
    'DOCU': 'DocuSign, Inc. provides cloud based software in the United States and internationally. The company provides e-signature solution that enables businesses to digitally prepare, sign, and manage agreements.',
    'CRM': 'Salesforce, Inc. provides Customer Relationship Management (CRM) technology that brings companies and customers together worldwide.',
    'WORK': 'Slack Technologies, Inc. operates a cloud-based collaboration hub that brings teams together to work as one.',
    'ZM': 'Zoom Video Communications, Inc. provides unified communications platform in the Americas, the Asia Pacific, Europe, the Middle East, and Africa.',
    
    // Healthcare & Biotech
    'JNJ': 'Johnson & Johnson researches and develops, manufactures, and sells various products in the health care field worldwide. It operates through three segments: Pharmaceutical, Medical Devices, and Consumer.',
    'UNH': 'UnitedHealth Group Incorporated operates as a diversified health care company in the United States. It operates through four segments: UnitedHealthcare, OptumHealth, OptumInsight, and OptumRx.',
    'PFE': 'Pfizer Inc. discovers, develops, manufactures, markets, distributes, and sells biopharmaceutical products worldwide. It operates through Pfizer Innovative Health (IH) and Pfizer Essential Health (EH) segments.',
    'ABBV': 'AbbVie Inc. discovers, develops, manufactures, and sells pharmaceuticals in the worldwide. The company focuses on developing and commercializing therapies to treat conditions across various therapeutic areas.',
    'TMO': 'Thermo Fisher Scientific Inc. offers life sciences solutions, analytical instruments, specialty diagnostics, and laboratory products and service worldwide.',
    'DHR': 'Danaher Corporation designs, manufactures, and markets professional, medical, industrial, and commercial products and services worldwide.',
    'BMY': 'Bristol-Myers Squibb Company discovers, develops, licenses, manufactures, and markets biopharmaceutical products worldwide.',
    'LLY': 'Eli Lilly and Company discovers, develops, and markets human pharmaceuticals worldwide. It offers Basaglar, Humalog, Humalog Mix 75/25, Humalog U-100, Humalog U-200, Humalog Mix 50/50, insulin lispro, insulin lispro protamine, insulin lispro mix 75/25, Humulin, Humulin 70/30, Humulin N, Humulin R, and Humulin U-500 for diabetes.',
  };
  
  static String getDescription(String symbol) {
    final description = _stockDescriptions[symbol.toUpperCase()];
    if (description != null) {
      return description;
    }
    
    // Generate a generic description based on symbol type
    if (symbol.endsWith('-USD')) {
      return 'A cryptocurrency that operates on a decentralized blockchain network, allowing for peer-to-peer transactions without the need for traditional financial intermediaries.';
    }
    
    // Check if it's likely an ETF
    final etfKeywords = ['SPY', 'QQQ', 'IWM', 'VT', 'VO', 'AR', 'SO', 'TL', 'GL', 'SL'];
    if (etfKeywords.any((keyword) => symbol.toUpperCase().contains(keyword)) || 
        symbol.length <= 4) {
      return 'An exchange-traded fund (ETF) that tracks the performance of a specific index, sector, commodity, or asset class, providing investors with diversified exposure through a single security.';
    }
    
    // Default stock description
    return 'A publicly traded company that operates in various business segments, providing products and services to consumers, businesses, and institutions globally.';
  }
  
  static String getShortDescription(String symbol) {
    final fullDescription = getDescription(symbol);
    // Return first sentence only
    final sentences = fullDescription.split('. ');
    return sentences.isNotEmpty ? '${sentences[0]}.' : fullDescription;
  }
  
  static String getCompanyType(String symbol) {
    if (symbol.endsWith('-USD')) {
      return 'Cryptocurrency';
    }
    
    // ETF detection
    final etfSymbols = ['SPY', 'QQQ', 'IWM', 'DIA', 'VOO', 'VTI', 'SOXL', 'SOXX', 'ARKK', 'GLD', 'TLT'];
    if (etfSymbols.contains(symbol.toUpperCase())) {
      return 'Exchange-Traded Fund (ETF)';
    }
    
    // Tech companies
    final techSymbols = ['AAPL', 'GOOGL', 'GOOG', 'MSFT', 'AMZN', 'META', 'TSLA', 'NVDA', 'NFLX', 'ORCL', 'CRM', 'ADBE'];
    if (techSymbols.contains(symbol.toUpperCase())) {
      return 'Technology Company';
    }
    
    // Financial companies
    final finSymbols = ['JPM', 'BAC', 'WFC', 'GS', 'MS', 'C', 'AXP', 'V', 'MA', 'PYPL'];
    if (finSymbols.contains(symbol.toUpperCase())) {
      return 'Financial Services';
    }
    
    return 'Public Company';
  }
}