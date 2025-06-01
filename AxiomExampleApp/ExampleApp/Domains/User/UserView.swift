import SwiftUI
import Axiom

// MARK: - User Domain View

/// Sophisticated user interface demonstrating advanced SwiftUI integration
/// with Axiom framework including authentication, profile management, and intelligence features
struct UserView: AxiomView {
    @ObservedObject var context: UserContext
    
    @State private var selectedTab: UserViewTab = .profile
    @State private var showingAdvancedFeatures = false
    @State private var showingPerformanceMetrics = false
    
    var body: some View {
        NavigationView {
            if context.isAuthenticated {
                authenticatedUserInterface
            } else {
                authenticationInterface
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            Task {
                await context.onAppear()
            }
        }
        .onDisappear {
            Task {
                await context.onDisappear()
            }
        }
        .alert("Validation Errors", isPresented: $context.showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(context.validationErrors.map { $0.rawValue }.joined(separator: "\n"))
        }
    }
    
    // MARK: - Authentication Interface
    
    private var authenticationInterface: some View {
        VStack(spacing: 24) {
            authenticationHeader
            
            if context.authenticationInProgress {
                authenticationProgress
            } else {
                authenticationForm
                oauthOptions
            }
            
            Spacer()
            
            if showingAdvancedFeatures {
                advancedAuthenticationFeatures
            }
        }
        .padding()
        .background(LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
    }
    
    private var authenticationHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("User Management Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Sophisticated Axiom Framework Integration")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Show Advanced Features") {
                showingAdvancedFeatures.toggle()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
    
    private var authenticationForm: some View {
        VStack(spacing: 16) {
            Group {
                TextField("Email", text: $context.loginEmail)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $context.loginPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
            }
            .frame(maxWidth: 300)
            
            if let error = context.loginError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            Button("Sign In") {
                Task {
                    await context.authenticateWithEmail()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(context.loginEmail.isEmpty || context.loginPassword.isEmpty)
            
            Button("Forgot Password?") {
                context.showingForgotPassword = true
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
    
    private var authenticationProgress: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Authenticating...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(height: 120)
    }
    
    private var oauthOptions: some View {
        VStack(spacing: 12) {
            Text("Or sign in with")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Button("Google") {
                    Task {
                        await context.authenticateWithOAuth(provider: "google")
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Apple") {
                    Task {
                        await context.authenticateWithOAuth(provider: "apple")
                    }
                }
                .buttonStyle(.bordered)
                
                Button("GitHub") {
                    Task {
                        await context.authenticateWithOAuth(provider: "github")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var advancedAuthenticationFeatures: some View {
        VStack(spacing: 12) {
            Text("Advanced Authentication Features")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Multi-factor authentication support")
                Text("• Biometric authentication integration")
                Text("• Session management with automatic refresh")
                Text("• Account lockout protection")
                Text("• Audit logging for security compliance")
                Text("• Advanced error recovery mechanisms")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Authenticated User Interface
    
    private var authenticatedUserInterface: some View {
        TabView(selection: $selectedTab) {
            userProfileTab
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(UserViewTab.profile)
            
            permissionsTab
                .tabItem {
                    Image(systemName: "key")
                    Text("Permissions")
                }
                .tag(UserViewTab.permissions)
            
            intelligenceTab
                .tabItem {
                    Image(systemName: "brain")
                    Text("Intelligence")
                }
                .tag(UserViewTab.intelligence)
            
            analyticsTab
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Analytics")
                }
                .tag(UserViewTab.analytics)
        }
        .navigationTitle("User Management")
        .navigationBarItems(
            leading: performanceButton,
            trailing: logoutButton
        )
        .sheet(isPresented: $context.showingProfileEditor) {
            profileEditorSheet
        }
        .sheet(isPresented: $showingPerformanceMetrics) {
            performanceMetricsSheet
        }
    }
    
    private var performanceButton: some View {
        Button("Metrics") {
            showingPerformanceMetrics = true
            Task {
                await context.loadUserMetrics()
            }
        }
        .font(.caption)
    }
    
    private var logoutButton: some View {
        Button("Logout") {
            Task {
                await context.logout()
            }
        }
        .foregroundColor(.red)
    }
    
    // MARK: - Profile Tab
    
    private var userProfileTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader
                profileDetails
                profileActions
                sessionInformation
            }
            .padding()
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: context.currentUser.isAuthenticated ? "person.crop.circle.fill" : "person.crop.circle")
                .font(.system(size: 80))
                .foregroundColor(context.currentUser.isAuthenticated ? .green : .gray)
            
            Text(context.currentUser.displayName.isEmpty ? "User" : context.currentUser.displayName)
                .font(.title)
                .fontWeight(.bold)
            
            Text(context.currentUser.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            profileCompletenessIndicator
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var profileCompletenessIndicator: some View {
        VStack(spacing: 8) {
            Text("Profile Completeness")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: context.currentUser.profileCompleteness)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 200)
            
            Text("\(Int(context.currentUser.profileCompleteness * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
    
    private var profileDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile Information")
                .font(.headline)
            
            ProfileDetailRow(label: "User ID", value: context.currentUser.id ?? "Not set")
            ProfileDetailRow(label: "Email", value: context.currentUser.email)
            ProfileDetailRow(label: "Display Name", value: context.currentUser.displayName)
            ProfileDetailRow(label: "Language", value: context.currentUser.preferredLanguage)
            ProfileDetailRow(label: "Account Status", value: context.currentUser.accountStatus.rawValue.capitalized)
            ProfileDetailRow(label: "Authentication Method", value: context.currentUser.authenticationMethod.rawValue.capitalized)
            
            if let lastActivity = context.currentUser.lastActivity {
                ProfileDetailRow(label: "Last Activity", value: DateFormatter.localizedString(from: lastActivity, dateStyle: .medium, timeStyle: .short))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var profileActions: some View {
        VStack(spacing: 12) {
            Button("Edit Profile") {
                context.startEditingProfile()
            }
            .buttonStyle(.borderedProminent)
            .disabled(context.profileUpdateInProgress)
            
            if context.currentUser.isLocked {
                Button("Unlock Account") {
                    Task {
                        await context.unlockAccount()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
            }
            
            Button("Refresh Session") {
                Task {
                    await context.refreshSession()
                }
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var sessionInformation: some View {
        Group {
            if let sessionInfo = context.sessionInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Information")
                        .font(.headline)
                    
                    ProfileDetailRow(label: "Session Token", value: sessionInfo.token)
                    ProfileDetailRow(label: "Expires", value: DateFormatter.localizedString(from: sessionInfo.expiry, dateStyle: .medium, timeStyle: .short))
                    ProfileDetailRow(label: "Status", value: sessionInfo.isActive ? "Active" : "Inactive")
                    
                    if sessionInfo.isExpiringSoon {
                        Text("⚠️ Session expires soon")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Permissions Tab
    
    private var permissionsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                permissionsHeader
                currentPermissions
                availablePermissions
            }
            .padding()
        }
    }
    
    private var permissionsHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Permission Management")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Manage user permissions and access rights")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var currentPermissions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Permissions")
                .font(.headline)
            
            if context.currentUser.permissions.isEmpty {
                Text("No permissions granted")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(Array(context.currentUser.permissions), id: \.self) { permission in
                    PermissionRow(
                        permission: permission,
                        isGranted: true,
                        onToggle: {
                            Task {
                                await context.revokePermission(permission)
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var availablePermissions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Permissions")
                .font(.headline)
            
            ForEach(context.availablePermissions.filter { !context.currentUser.permissions.contains($0) }, id: \.self) { permission in
                PermissionRow(
                    permission: permission,
                    isGranted: false,
                    onToggle: {
                        Task {
                            await context.grantPermission(permission)
                        }
                    )
                )
            }
            
            if let error = context.permissionError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Intelligence Tab
    
    private var intelligenceTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                intelligenceHeader
                intelligenceQuerySection
                intelligenceResponseSection
                prebuiltQueries
            }
            .padding()
        }
    }
    
    private var intelligenceHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundColor(.purple)
            
            Text("AI Intelligence Integration")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Explore user insights through natural language queries")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var intelligenceQuerySection: some View {
        VStack(spacing: 12) {
            Text("Ask About This User")
                .font(.headline)
            
            TextField("Enter your question...", text: $context.intelligenceQuery, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
            
            HStack(spacing: 12) {
                Button("Analyze User") {
                    Task {
                        await context.askIntelligenceAboutUser()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(context.intelligenceInProgress)
                
                Button("Security Analysis") {
                    Task {
                        await context.askIntelligenceAboutSecurity()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(context.intelligenceInProgress)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var intelligenceResponseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intelligence Response")
                .font(.headline)
            
            if context.intelligenceInProgress {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if !context.intelligenceResponse.isEmpty {
                Text(context.intelligenceResponse)
                    .font(.body)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Text("No response yet. Ask a question to get AI insights.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var prebuiltQueries: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Queries")
                .font(.headline)
            
            VStack(spacing: 8) {
                SuggestedQueryButton(
                    title: "Profile Optimization",
                    query: "How can this user improve their profile completeness?",
                    icon: "person.badge.plus"
                ) { query in
                    context.intelligenceQuery = query
                }
                
                SuggestedQueryButton(
                    title: "Security Assessment",
                    query: "What security improvements should this user consider?",
                    icon: "shield.checkered"
                ) { query in
                    context.intelligenceQuery = query
                }
                
                SuggestedQueryButton(
                    title: "Permission Analysis",
                    query: "Analyze this user's permissions and suggest optimizations.",
                    icon: "key.horizontal"
                ) { query in
                    context.intelligenceQuery = query
                }
                
                SuggestedQueryButton(
                    title: "Activity Insights",
                    query: "What patterns can you identify in this user's activity?",
                    icon: "chart.line.uptrend.xyaxis"
                ) { query in
                    context.intelligenceQuery = query
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Analytics Tab
    
    private var analyticsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                analyticsHeader
                userActionHistory
                performanceOverview
            }
            .padding()
        }
    }
    
    private var analyticsHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("User Analytics")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Track user activity and performance metrics")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var userActionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Actions")
                .font(.headline)
            
            if context.userActionHistory.isEmpty {
                Text("No actions recorded yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(context.userActionHistory.suffix(10).indices, id: \.self) { index in
                    let record = context.userActionHistory[index]
                    UserActionRow(record: record)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var performanceOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
            
            if let metrics = context.performanceMetrics {
                VStack(spacing: 8) {
                    MetricRow(label: "Total Operations", value: "\(metrics.totalOperations)")
                    MetricRow(label: "Avg Response Time", value: String(format: "%.3f s", metrics.averageResponseTime))
                    MetricRow(label: "Auth Latency", value: String(format: "%.3f s", metrics.authenticationLatency))
                    MetricRow(label: "Cache Hit Rate", value: String(format: "%.1f%%", metrics.cacheHitRate * 100))
                    MetricRow(label: "Error Rate", value: String(format: "%.2f%%", metrics.errorRate * 100))
                }
            } else {
                Text("Loading metrics...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Profile Editor Sheet
    
    private var profileEditorSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    TextField("Display Name", text: $context.editedDisplayName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Email", text: $context.editedEmail)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    if let error = context.profileSaveError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarItems(
                leading: Button("Cancel") {
                    context.showingProfileEditor = false
                },
                trailing: Button("Save") {
                    Task {
                        await context.saveProfileChanges()
                    }
                }
                .disabled(context.profileUpdateInProgress)
            )
        }
    }
    
    // MARK: - Performance Metrics Sheet
    
    private var performanceMetricsSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let metrics = context.performanceMetrics {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Detailed Performance Metrics")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            MetricSection(title: "Operation Metrics") {
                                MetricRow(label: "Total Operations", value: "\(metrics.totalOperations)")
                                MetricRow(label: "Active Observers", value: "\(metrics.activeObservers)")
                            }
                            
                            MetricSection(title: "Response Times") {
                                MetricRow(label: "Average Response", value: String(format: "%.3f s", metrics.averageResponseTime))
                                MetricRow(label: "Authentication", value: String(format: "%.3f s", metrics.authenticationLatency))
                                MetricRow(label: "State Updates", value: String(format: "%.3f s", metrics.stateUpdateLatency))
                                MetricRow(label: "Validation", value: String(format: "%.3f s", metrics.validationLatency))
                            }
                            
                            MetricSection(title: "Efficiency Metrics") {
                                MetricRow(label: "Cache Hit Rate", value: String(format: "%.1f%%", metrics.cacheHitRate * 100))
                                MetricRow(label: "Error Rate", value: String(format: "%.2f%%", metrics.errorRate * 100))
                            }
                        }
                    } else {
                        Text("No metrics available")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Done") {
                showingPerformanceMetrics = false
            })
        }
    }
}

// MARK: - Supporting Views

private struct ProfileDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
        }
    }
}

private struct PermissionRow: View {
    let permission: UserPermission
    let isGranted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isGranted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(permission.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(permissionDescription(for: permission))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(isGranted ? "Revoke" : "Grant") {
                onToggle()
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
    
    private func permissionDescription(for permission: UserPermission) -> String {
        switch permission {
        case .profileRead:
            return "Read profile information"
        case .profileWrite:
            return "Edit profile information"
        case .accountDelete:
            return "Delete account permanently"
        case .subscriptionManage:
            return "Manage subscription settings"
        case .analyticsRead:
            return "View analytics data"
        case .userManagement:
            return "Manage other users"
        }
    }
}

private struct SuggestedQueryButton: View {
    let title: String
    let query: String
    let icon: String
    let onSelect: (String) -> Void
    
    var body: some View {
        Button(action: { onSelect(query) }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(query)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(6)
    }
}

private struct UserActionRow: View {
    let record: UserActionRecord
    
    var body: some View {
        HStack {
            Image(systemName: iconForAction(record.action))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(actionDescription(record.action))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(DateFormatter.localizedString(from: record.timestamp, dateStyle: .none, timeStyle: .short))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func iconForAction(_ action: UserAction) -> String {
        switch action {
        case .viewProfile: return "eye"
        case .editProfile: return "pencil"
        case .deleteAccount: return "trash"
        case .manageSubscription: return "creditcard"
        case .accessAnalytics: return "chart.bar"
        case .manageUsers: return "person.3"
        }
    }
    
    private func actionDescription(_ action: UserAction) -> String {
        switch action {
        case .viewProfile: return "Viewed Profile"
        case .editProfile: return "Edited Profile"
        case .deleteAccount: return "Deleted Account"
        case .manageSubscription: return "Managed Subscription"
        case .accessAnalytics: return "Accessed Analytics"
        case .manageUsers: return "Managed Users"
        }
    }
}

private struct MetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

private struct MetricSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            VStack(spacing: 8) {
                content()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Types

private enum UserViewTab: CaseIterable {
    case profile
    case permissions
    case intelligence
    case analytics
}

// MARK: - Preview

struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        let mockClient = UserClient(capabilities: CapabilityManager())
        let mockIntelligence = DefaultAxiomIntelligence()
        let context = UserContext(userClient: mockClient, intelligence: mockIntelligence)
        
        UserView(context: context)
    }
}