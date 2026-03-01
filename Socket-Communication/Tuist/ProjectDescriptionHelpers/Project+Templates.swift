//
//  Project+Templates.swift
//  Config
//
//  Created by Taemin Yun on 2026-03-01.
//

import ProjectDescription

public extension Project {
    
    static func app(
        name: String,
        infoPlist: InfoPlist? = .default,
        dependencies: [ProjectDescription.TargetDependency] = []
    ) -> Self {
        Project(
            name: name,
            targets: [
                .app(
                    name: name,
                    infoPlist: infoPlist,
                    sources: ["\(name)/Sources/**"],
                    resources: ["\(name)/Resources/**"],
                    dependencies: dependencies
                )
            ],
            schemes: [
                .scheme(
                    name: name,
                    buildAction: .buildAction(
                        targets: [.init(stringLiteral: name)]
                    ),
                    testAction: .testPlans(
                        [.relativeToRoot("\(name)Tests/\(name).xctestplan")]
                    )
                )
            ]
        )
    }
    
    static func framework(
        name: String,
        infoPlist: InfoPlist? = .default,
        sources: SourceFilesList? = ["Sources/**"],
        resources: ResourceFileElements? = nil,
        uiTestsSources: SourceFilesList? = nil,
        dependencies: [ProjectDescription.TargetDependency] = []
    ) -> Self {
        var targets: [Target] = [
            .framework(
                name: name,
                infoPlist: infoPlist,
                sources: sources,
                resources: resources,
                dependencies: dependencies
            )
        ]
        
        if let uiTestsSources {
            targets.append(
                .uiTests(
                    name: name,
                    infoPlist: infoPlist,
                    sources: uiTestsSources,
                    dependencies: dependencies
                )
            )
        }
        
        return Project(
            name: name,
            targets: targets
        )
    }
}

private extension Target {

    static let destinations: Destinations = .iOS
    static let deploymentTargets: DeploymentTargets = .iOS("16.0")
    
    static func app(
        name: String,
        infoPlist: InfoPlist?,
        sources: SourceFilesList?,
        resources: ResourceFileElements?,
        dependencies: [ProjectDescription.TargetDependency]
    ) -> Self {
        .target(
            name: name,
            destinations: Self.destinations,
            product: .app,
            bundleId: "dev.tuist.\(name)",
            deploymentTargets: Self.deploymentTargets,
            infoPlist: infoPlist,
            sources: sources,
            resources: resources,
            dependencies: dependencies
        )
    }
    
    static func uiTests(
        name: String,
        infoPlist: InfoPlist?,
        sources: SourceFilesList? = "Tests/**",
        dependencies: [ProjectDescription.TargetDependency] = []
    ) -> Self {
        .target(
            name: "\(name)Tests",
            destinations: Self.destinations,
            product: .unitTests,
            bundleId: "dev.tuist.\(name)Tests",
            deploymentTargets: Self.deploymentTargets,
            infoPlist: infoPlist,
            sources: sources,
            dependencies: dependencies
        )
    }
    
    static func framework(
        name: String,
        infoPlist: InfoPlist?,
        sources: SourceFilesList?,
        resources: ResourceFileElements?,
        dependencies: [ProjectDescription.TargetDependency]
    ) -> Self {
        .target(
            name: name,
            destinations: Self.destinations,
            product: .framework,
            bundleId: "dev.tuist.\(name)",
            deploymentTargets: Self.deploymentTargets,
            infoPlist: infoPlist,
            sources: sources,
            resources: resources,
            dependencies: dependencies
        )
    }
    
}

