//
//  ViewController.swift
//  FormsSample
//
//  Created by Chris Eidhof on 22.03.18.
//  Copyright © 2018 objc.io. All rights reserved.
//

import UIKit

struct Hotspot {
    var isEnabled: Bool = true
    var password: String = "hello"
}

extension Hotspot {
    var enabledSectionTitle: String? {
        return isEnabled ? "Personal Hotspot Enabled" : nil
    }
}

final class TargetAction {
    let execute: () -> ()
    init(_ execute: @escaping () -> ()) {
        self.execute = execute
    }
    @objc func action(_ sender: Any) {
        execute()
    }
}

struct Observer {
    var strongReferences: [Any]
    var update: (Hotspot) -> ()
}

func hotspotForm(state: Hotspot, change: @escaping ((inout Hotspot) -> ()) -> (), pushViewController: @escaping (UIViewController) -> ()) -> ([Section], Observer) {
    var strongReferences: [Any] = []
    var updates: [(Hotspot) -> ()] = []
    
    let toggleCell = FormCell(style: .value1, reuseIdentifier: nil)
    let toggle = UISwitch()
    toggleCell.textLabel?.text = "Personal Hotspot"
    toggleCell.contentView.addSubview(toggle)
    toggle.isOn = state.isEnabled
    toggle.translatesAutoresizingMaskIntoConstraints = false
    let toggleTarget = TargetAction {
        change { $0.isEnabled = toggle.isOn }
    }
    strongReferences.append(toggleTarget)
    updates.append { state in
        toggle.isOn = state.isEnabled
    }
    toggle.addTarget(toggleTarget, action: #selector(TargetAction.action(_:)), for: .valueChanged)
    toggleCell.contentView.addConstraints([
        toggle.centerYAnchor.constraint(equalTo: toggleCell.contentView.centerYAnchor),
        toggle.trailingAnchor.constraint(equalTo: toggleCell.contentView.layoutMarginsGuide.trailingAnchor)
        ])
    
    
    let passwordCell = FormCell(style: .value1, reuseIdentifier: nil)
    passwordCell.textLabel?.text = "Password"
    passwordCell.detailTextLabel?.text = state.password
    passwordCell.accessoryType = .disclosureIndicator
    passwordCell.shouldHighlight = true
    updates.append { state in
        passwordCell.detailTextLabel?.text = state.password
    }

    
    let passwordDriver = PasswordDriver(password: state.password) { newPassword in
        change({ $0.password = newPassword })
    }
    passwordCell.didSelect = {
        pushViewController(passwordDriver.formViewController)
    }
    
    let toggleSection = Section(cells: [toggleCell], footerTitle: state.enabledSectionTitle)
    updates.append { state in
        toggleSection.footerTitle = state.enabledSectionTitle
    }

    return ([
        toggleSection,
        Section(cells: [
            passwordCell
            ], footerTitle: nil),
        ], Observer(strongReferences: strongReferences) { state in
            for u in updates {
                u(state)
            }
        }
    )
}


class FormDriver {
    var formViewController: FormViewController!
    var sections: [Section] = []
    var observer: Observer!
    
    init(initial state: Hotspot, build: (Hotspot, @escaping ((inout Hotspot) -> ()) -> (), _ pushViewController:  @escaping (UIViewController) -> ()) -> ([Section], Observer)) {
        self.state = state
        let (sections, observer) = build(state, { [unowned self] f in
            f(&self.state)
        }, { [unowned self] vc in
            self.formViewController.navigationController?.pushViewController(vc, animated: true)
        })
        self.sections = sections
        self.observer = observer
        formViewController = FormViewController(sections: sections, title: "Personal Hotspot Settings")
    }
    
    var state = Hotspot() {
        didSet {
            observer.update(state)
            formViewController.reloadSectionFooters()
        }
    }
}

class PasswordDriver {
    let textField = UITextField()
    let onChange: (String) -> ()
    var formViewController: FormViewController!
    var sections: [Section] = []
    
    init(password: String, onChange: @escaping (String) -> ()) {
        self.onChange = onChange
        buildSections()
        self.formViewController = FormViewController(sections: sections, title: "Hotspot Password", firstResponder: textField)
        textField.text = password
    }
    
    func buildSections() {
        let cell = FormCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = "Password"
        cell.contentView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addConstraints([
            textField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
            textField.leadingAnchor.constraint(equalTo: cell.textLabel!.trailingAnchor, constant: 20)
            ])
        textField.addTarget(self, action: #selector(editingEnded(_:)), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(editingDidEnter(_:)), for: .editingDidEndOnExit)

        sections = [
            Section(cells: [cell], footerTitle: nil)
        ]
    }
    
    @objc func editingEnded(_ sender: Any) {
        onChange(textField.text ?? "")
    }
    
    @objc func editingDidEnter(_ sender: Any) {
        onChange(textField.text ?? "")
        formViewController.navigationController?.popViewController(animated: true)
    }
}




