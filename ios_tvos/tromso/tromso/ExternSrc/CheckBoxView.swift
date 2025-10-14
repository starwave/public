//
//  CheckBox.swift
//  tromso
//
//  Created by Brad Park on 10/6/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import SwiftUI

struct CheckBoxView: View {
    @State var checked: Bool = false
    @State var label: String = ""
	@State var onClicked: () -> Void = {}

    var body: some View {
		HStack{
			Image(systemName: checked ? "checkmark.square.fill" : "square")
				.foregroundColor(checked ? Color(UIColor.systemBlue) : Color.secondary)
				.onTapGesture {
					self.checked.toggle()
					self.onClicked()
				}
			Text(label)
		}
    }
}

struct CheckBoxView_Previews: PreviewProvider {
    static var previews: some View {
        CheckBoxView()
    }
}

//struct CheckBoxView_Previews: PreviewProvider {
//    struct CheckBoxViewHolder: View {
//        @State var checked = false
//		@State var label = "CheckBoxView"
//		@State var onClicked = {}
//
//        var body: some View {
//			CheckBoxView(checked: $checked, label:$label, onClicked: $onClicked)
//        }
//    }
//
//    static var previews: some View {
//        CheckBoxViewHolder()
//    }
//}

