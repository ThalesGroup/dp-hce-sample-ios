/*
 MIT License
 
 Copyright (c) 2021 Thales DIS

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */
  
import SwiftUI

struct CardFrontDetailView: View {
    var cardDetail:CardDetail

    var body: some View {
        Spacer()
        Text("\(self.cardDetail.pan.format(self.cardDetail.pan))")
            .foregroundColor(Color.white)
            .font(.system(size: 28))
            .lineLimit(1)
        Spacer()
        HStack {
            if (self.cardDetail.cvv != "***") {
                VStack(alignment: .leading) {
                    Text(LocalizedStringKey("title_cvv"))
                        .font(.caption)
                        .foregroundColor(Color.white)
                    HStack {
                        Text(self.cardDetail.cvv)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(LocalizedStringKey("title_valid_thru"))
                    .font(.caption)
                    .foregroundColor(Color.white)
                HStack {
                    Text(self.cardDetail.cardExpiryDateMonth())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.white)
                    Text("/")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.white)
                    Text(self.cardDetail.cardExpiryDateYear())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.white)
                }
            }
        }
        .padding(.bottom, 10)
        .padding(.leading, 10)
        .padding(.trailing, 10)
    }
}

/**
 View to dispaly the card image and details.
 */
struct CardFrontView: View {
    var cardDetail:CardDetail
    
    var body: some View {
        if (self.cardDetail.backgroundImage != nil) {
                ZStack {
                    let image = UIImage(data: self.cardDetail.backgroundImage!)
                        Image(uiImage: image!).resizable()
                            .aspectRatio(contentMode: .fill)
                    VStack(alignment: .center) {
                        CardFrontDetailView(cardDetail: cardDetail)
                        }
                        .padding(.bottom, 10)
                        .padding(.leading, 10)
                        .padding(.trailing, 10)
                }.frame(width: 330.0, height: 200.0)
                .cornerRadius(20)
        } else {
            VStack(alignment: .center) {
                    HStack(alignment: .center) {
                        Spacer()
                        Image("Thales_logo")
                    }
                    CardFrontDetailView(cardDetail: cardDetail)
            }.frame(width: 330.0, height: 200.0)
            .background(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.3306755424, green: 0.7205328345, blue: 0.9244166613, alpha: 1)), Color.blue]), startPoint: .topLeading, endPoint: .bottomLeading))
            .cornerRadius(20)
        }
    }
}

struct CardFrontView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CardFrontView(cardDetail: CardDetail(pan: "4123450131003313", cardExpiryDate: "1025", cvv: "522", backgroundImage: nil, cardState: .DIGITALIZED_CARD_STATE_ACTIVE))

        }
    }
}

extension String {
    
    func format(_ str: String) -> String {
        switch str.count {
        case 0...4:
            return str
        case 4:
            let index = str.index(str.startIndex, offsetBy: 4)
            return String(str[..<index]) + " " + String(str[index...])
        default:
            let index = str.index(str.startIndex, offsetBy: 4)
            return String(str[..<index]) + " " + format(String(str[index...]))
        }
    }
}
