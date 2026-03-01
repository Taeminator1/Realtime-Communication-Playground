import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.app(
    name: "Socket-Communication",
    infoPlist: .extendingDefault(
        with: [
            "UILaunchScreen": [
                "UIColorName": "",
                "UIImageName": "",
            ],
        ]
    ),
    dependencies: [
        .project(target: "BSDSockets", path: .relativeToRoot("Frameworks/BSDSockets"), status: .required),
    ]
)
