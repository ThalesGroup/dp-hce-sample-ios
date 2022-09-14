//
// Copyright © 2021-2022 THALES. All rights reserved.
//

import SwiftUI

/**
 Notification view to display mainly error messages.
 */
struct NotificationView: ViewModifier {
        
    @Binding var data:NotificationData?
    @Binding var show:Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if show {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(data!.title)
                                .bold()
                            Text(data!.detail)
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
                .animation(.linear, value: 0)
                .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                .onTapGesture {
                    withAnimation {
                        self.show = false
                    }
                }.onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            self.show = false
                        }
                    }
                })
            }
        }
    }
}

extension View {
    
    func banner(data: Binding<NotificationData?>, show: Binding<Bool>) -> some View {
        self.modifier(NotificationView(data: data, show: show))
    }
}

struct Notification_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            Text("Hello")
        }.banner(data: .constant(NotificationData(title: "test", detail: "test", type: NotificationType.Info)), show: .constant(true))
    }
}

