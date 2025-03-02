/*
 * Copyright © 2024 THALES. All rights reserved.
 */

import SwiftUI

enum ToastType {
    case info
    case warning
    case success
    case error
    
    var tintColor: Color {
        switch self {
        case .info:
            return Color(UIColor.tintColor)
        case .success:
            return Color.green
        case .warning:
            return Color.yellow
        case .error:
            return Color.red
        }
    }
}

struct ToastData: Equatable {
    var caption: String
    var description: String
    var type: ToastType
    var timeout: Double = 4
}

class ToastHelper: NSObject {
    @Published var toastData: ToastData? = nil

    public func toastData(data: ToastData) {
        DispatchQueue.main.async {
            self.toastData = data
        }
    }
    
    public func toastShow(caption: String, description: String, type: ToastType = .info) {
        DispatchQueue.main.async {
            self.toastData = ToastData(caption: caption, description: description, type: type)
        }
    }
    
    public func toastHide() {
        DispatchQueue.main.async {
            self.toastData = nil
        }
    }
}

/// Notification View.
struct NotificationViewModifier: ViewModifier {
    
    @Binding var data: ToastData?
    
    @State var timer: Timer? = nil
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if data != nil {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(data!.caption)
                                .bold()
                            Text(data!.description)
                                .font(Font.system(size: 15, weight: Font.Weight.light, design: Font.Design.default))
                        }
                        Spacer()
                    }
                    .foregroundColor(Color.white)
                    .padding(12)
                    .background(data!.type.tintColor)
                    .cornerRadius(8)
                    Spacer()
                }
                .padding()
                .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                .onTapGesture {
                    data = nil
                }
            }
        }
        .animation(.easeInOut, value: data != nil)
        .onChange(of: data) { oldValue, newValue in
            rescheduleTimer()
        }
        
    }
    
    private func rescheduleTimer() {
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
        if data != nil {
            timer = Timer.scheduledTimer(withTimeInterval: data!.timeout, repeats: false) { timer in
                data = nil
                timer.invalidate()
                self.timer = nil
            }
        }
    }
}

func notificationViewModifier(data: Binding<ToastData?>) -> some View {
    EmptyView().modifier(NotificationViewModifier(data: data))
}

#Preview("Basic info toast") {
    notificationViewModifier(data: .constant(ToastData(caption: "Caption",
                                                       description: "Description",
                                                       type: .info)))
}
