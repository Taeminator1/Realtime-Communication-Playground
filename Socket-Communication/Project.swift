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
        .project(target: "BSDSocket", path: .relativeToRoot("Frameworks/BSDSocket"), status: .required),
        .project(target: "SocketClient", path: .relativeToRoot("Frameworks/SocketClient"), status: .required),
    ]
)
