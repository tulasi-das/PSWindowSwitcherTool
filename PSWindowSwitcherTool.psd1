@{
    RootModule = 'PSWindowSwitcherTool.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'e7a0b7d9-1234-4bcd-9a67-abcdef123456'  # Generate your own GUID
    Author = 'Tulasidas Biradar'
    Description = 'A PowerShell module with GUI to switch between open windows.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Start-PSWindowSwitcherTool')
    RequiredAssemblies = @()
    NestedModules = @()
    FileList = @('PSWindowSwitcherTool.psm1')
    PrivateData = @{
        PSData = @{
            Tags = @('windows','gui','windows-switcher','powershell')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/tulasi-das/PSWindowSwitcherTool'
            ReleaseNotes = 'Initial release. See README at ProjectUri for usage details.'
        }
    }
}
