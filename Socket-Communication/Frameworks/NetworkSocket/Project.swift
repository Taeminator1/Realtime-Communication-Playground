import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
    name: "NetworkSocket",
    dependencies: [
        .project(target: "SocketClient", path: .relativeToRoot("Frameworks/SocketClient"), status: .required),
    ]
)
