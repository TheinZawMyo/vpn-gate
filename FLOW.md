Create a complete, production-ready Flutter VPN application that fetches free public VPN servers from the official VPN Gate API and allows users to connect using the OpenVPN protocol.

### Technical Stack & Requirements:
1. **Framework:** Flutter (latest stable version, Dart).
2. **State Management:** Provider or Riverpod for handling app state (server list, loading state, connection status).
3. **Dependencies:** 
   - `http`: For fetching the VPN Gate CSV endpoint.
   - `csv`: For parsing the CSV data.
   - `open_vpn_flutter` (or equivalent robust OpenVPN plugin for Flutter): For handling the actual OpenVPN background tunnel connection.
   - `flutter_secure_storage` or shared preferences (if needed).

### Key Features to Implement:
1. **Fetch & Parse VPN Gate API:**
   - Call the endpoint: `https://www.vpngate.net/api/iphone/`
   - Skip the first 2 comment lines of the CSV response.
   - Parse the CSV rows into a custom Dart model (`VpnServer`) containing fields: `hostName`, `ip`, `countryLong`, `countryShort`, `ping`, `speed`, `score`, and `openVpnConfigData` (Base64 decoded string).
   - Handle network errors gracefully with try-catch blocks and a retry button.

2. **Server List UI:**
   - Display the fetched servers in a clean `ListView` or `GridView`.
   - Show server details such as Country Flag/Name, Ping (latency in ms), and Speed.
   - Add a search/filter bar to filter servers by country.

3. **OpenVPN Connection Handler:**
   - When a user taps a server, extract its `openVpnConfigData` (decode from Base64 if needed).
   - Pass the `.ovpn` configuration text configuration string to the OpenVPN plugin.
   - Implement connection states: `Disconnected`, `Connecting`, `Connected`, `Disconnecting`, and `Error`.
   - Show a dedicated Connection Screen or bottom sheet with real-time status updates, IP info, and a disconnect button.

4. **Architecture & Clean Code:**
   - Follow clean architecture principles (separate models, services/repositories, state management, and UI screens).
   - Include null-safety, error handling, and proper resource disposal.

Please provide the complete folder structure and code files (main.dart, vpn_model.dart, vpn_service.dart, vpn_provider.dart, home_screen.dart, connection_screen.dart) needed to get this running.