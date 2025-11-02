//
//  PreferenceUIHostingController.swift
//  tromso_ios
//
//  Created by Brad Park on 5/21/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import SwiftUI

struct PrefersHomeIndicatorAutoHiddenPreferenceKey: PreferenceKey {
    typealias Value = Bool
    static var defaultValue: Value = false
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue() || value
    }
}

extension View {
    // Controls the application's preferred home indicator auto-hiding when this view is shown.
    func prefersHomeIndicatorAutoHidden(_ value: Bool) -> some View {
        preference(key: PrefersHomeIndicatorAutoHiddenPreferenceKey.self, value: value)
    }
}

class PreferenceUIHostingController: UIHostingController<AnyView> {
    init<V: View>(wrappedView: V) {
        let box = Box()
        super.init(rootView: AnyView(wrappedView
            .onPreferenceChange(PrefersHomeIndicatorAutoHiddenPreferenceKey.self) {
                box.value?._prefersHomeIndicatorAutoHidden = $0
            }
        ))
        box.value = self
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private class Box {
        weak var value: PreferenceUIHostingController?
        init() {}
    }

    // MARK: Prefers Home Indicator Auto Hidden
    private var _prefersHomeIndicatorAutoHidden = false {
        didSet { setNeedsUpdateOfHomeIndicatorAutoHidden() }
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
        _prefersHomeIndicatorAutoHidden
    }
}
