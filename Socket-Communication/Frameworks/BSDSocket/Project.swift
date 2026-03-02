import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
    name: "BSDSocket",
    dependencies: [
        .project(target: "SocketClient", path: .relativeToRoot("Frameworks/SocketClient"), status: .required),
    ]
)
