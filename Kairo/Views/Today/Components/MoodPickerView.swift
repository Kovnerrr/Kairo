//
//  MoodPickerView.swift
//  Kairo
//
//  Created by Andrii Kovner on 08.09.26.
//

import SwiftUI

struct MoodPickerView: View {
    let selectedMood: MoodType?
    let onSelectMood: (MoodType) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(MoodType.allCases) { mood in
                Button {
                    onSelectMood(mood)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: mood.symbolName)
                            .font(.system(size: 22))
                            .frame(width: 28, height: 28)
                        
                        Text(mood.title)
                            .font(AppTheme.Typography.badge)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(selectedMood == mood ? AppTheme.accent : .secondary)
                    .background(selectedMood == mood ? AppTheme.accentSoft : AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .stroke(
                                selectedMood == mood ? AppTheme.accent : AppTheme.border,
                                lineWidth: 1
                            )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mood.title)
                .accessibilityAddTraits(selectedMood == mood ? .isSelected : [])
            }
        }
    }
}

#Preview("No Selection") {
    MoodPickerView(selectedMood: nil, onSelectMood: { _ in })
        .padding()
}

#Preview("Good Selected") {
    MoodPickerView(selectedMood: .good, onSelectMood: { _ in })
        .padding()
}
