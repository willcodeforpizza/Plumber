<#
    .SYNOPSIS
    A parent task to run all meta style tasks in the validation pipeline
#>
task Meta ?PublicFunctions, 
    ?Structure,
    ?Naming,
    ?Psd1Data,
    ?ToDo
