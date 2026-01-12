import SwiftUI

// MARK: - Reusable Styles & Components

struct ProfileHeaderView: View {
    let image: Image
    let name: String
    let role: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.cardBackground, lineWidth: 4))
                
                Image(systemName: "camera.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Theme.accent)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.cardBackground, lineWidth: 3))
                    .offset(x: 4, y: 4)
            }
            
            VStack(spacing: 4) {
                Text(name)
                    .font(.title2)
                    .bold()
                    .foregroundColor(Theme.primaryText)
                
                Text(role)
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
    }
}

struct InfoRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.secondaryText)
                .textCase(.uppercase)
            
            Text(value)
                .font(.body)
                .foregroundColor(Theme.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.secondaryText)
                .textCase(.uppercase)
            
            TextField("", text: $text)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .foregroundColor(Theme.primaryText)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

struct EditableInfoSection<Content: View, EditContent: View>: View {
    let title: String
    @Binding var isEditing: Bool
    let onSave: () -> Void
    let content: () -> Content
    let editContent: () -> EditContent
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.primaryText)
                
                Spacer()
                
                Button {
                    if isEditing {
                        onSave() // Logic to save handled by parent/VM
                    } else {
                        withAnimation {
                            isEditing = true
                        }
                    }
                } label: {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(isEditing ? .green : Theme.accent)
                }
            }
            
            Divider()
                .background(Theme.gridLine)
            
            Group {
                if isEditing {
                    editContent()
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                } else {
                    content()
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
    }
}
