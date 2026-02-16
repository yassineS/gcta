# GCTA GitHub Configuration

This directory contains GitHub Actions workflows and configuration for automated GCTA binary builds.

## 📁 Directory Structure

```
.github/
├── README.md                          # This file  
├── IMPLEMENTATION_SUMMARY.md          # Technical overview
├── GITHUB_ACTIONS_GUIDE.md           # Setup and usage guide
└── workflows/
    ├── README.md                      # Workflow documentation
    ├── build-linux-x86_64.yml         # Linux x86_64 build
    ├── build-linux-arm64.yml          # Linux ARM64 build
    ├── build-macos-intel.yml          # macOS Intel build
    ├── build-macos-arm64.yml          # macOS ARM64 build
    ├── build-all-platforms.yml        # Master orchestrator
    └── release.yml                    # Release automation
```

## 🚀 Quick Start

### For Users

**Want to download pre-built binaries?**

1. Go to [GitHub Releases](https://github.com/jianyangqt/gcta/releases)
2. Download the binary for your platform
3. Extract and run

**Need help with setup?**
- See [GITHUB_ACTIONS_GUIDE.md](./GITHUB_ACTIONS_GUIDE.md)

### For Developers

**Want to trigger a build?**

```bash
# Trigger Linux x86_64 build
gh workflow run build-linux-x86_64.yml

# Or trigger all platforms
gh workflow run build-all-platforms.yml
```

**Want to create a release?**

```bash
# Tag and push to trigger automatic release
git tag v2.1.0
git push origin v2.1.0
```

## 📚 Documentation

### Main Guide: GITHUB_ACTIONS_GUIDE.md
- **Purpose:** Complete setup and usage guide for GitHub Actions
- **Audience:** DevOps, CI/CD engineers, maintainers
- **Contents:**
  - Setup instructions
  - Workflow overview
  - Common tasks
  - Troubleshooting

**Start here if you're setting up for the first time.**

### Technical Reference: IMPLEMENTATION_SUMMARY.md
- **Purpose:** Technical details and architectural overview
- **Audience:** Developers interested in CI/CD implementation
- **Contents:**
  - What was created
  - Build flow
  - Configuration options
  - Maintenance notes

**Start here if you need technical details.**

### Workflow Documentation: workflows/README.md
- **Purpose:** Detailed workflow reference
- **Audience:** Developers modifying workflows
- **Contents:**
  - Individual workflow descriptions
  - Trigger conditions
  - Customization guide
  - Performance metrics

**Start here for workflow-specific details.**

## 🎯 What These Workflows Do

### Automatic Builds (6 Workflows)

| Workflow | Platform | Trigger | Output |
|----------|----------|---------|--------|
| build-linux-x86_64.yml | Linux x86_64 | Push, PR, Tag | Binary + checksums |
| build-linux-arm64.yml | Linux ARM64 | Push, PR, Tag | Binary + checksums |
| build-macos-intel.yml | macOS Intel | Push, PR, Tag | Binary + checksums |
| build-macos-arm64.yml | macOS ARM64 | Push, PR, Tag | Binary + checksums |
| build-all-platforms.yml | All 4 | Manual, Tag | All artifacts |
| release.yml | Release | Tag, Manual | GitHub Release |

### Key Features

✅ **Fully Automated** - No manual intervention required  
✅ **Multi-Platform** - Builds for 4 platform combinations  
✅ **Release Ready** - Creates GitHub Release with all binaries  
✅ **Checksums** - MD5 and SHA256 for verification  
✅ **Configurable** - Manual triggers with platform selection  

## 🔄 How It Works

```
Developer pushes code
         ↓
GitHub Actions triggered
         ↓
┌────────────────────┐
│  Platform builds   │
│ (parallel or        │
│  sequential)       │
└────────────────────┘
         ↓
  Artifacts uploaded
         ↓
   Release created
(if tagged with v*)
         ↓
 GitHub Release published
```

## 🚀 Usage Examples

### Automatic Release

Most common workflow for releases:

```bash
# 1. Create version tag
git tag v2.1.0

# 2. Push tag to GitHub
git push origin v2.1.0

# 3. GitHub Actions automatically:
#    - Builds all 4 platforms
#    - Creates GitHub Release
#    - Publishes binaries
```

### Manual Platform Build

Build specific platform on demand:

```bash
gh workflow run build-linux-x86_64.yml

# Or with parameters
gh workflow run build-all-platforms.yml -f build_type=macos-intel
```

### Download Binaries

Once builds complete:

```bash
# List recent builds
gh run list --workflow build-linux-x86_64.yml

# Download artifacts
gh run download <run_id> -n gcta64_linux_x86_64
```

## 📊 Build Times

| Platform | Time |
|----------|------|
| Linux x86_64 | 60-90 min |
| Linux ARM64 | 60-90 min |
| macOS Intel | 50-80 min |
| macOS ARM64 | 40-70 min |
| **All Parallel** | ~90 min |
| **Release Creation** | ~30 min |

## 🔧 Customization

### Quick Changes

**Change artifact retention:**
Edit `workflows/build-*.yml` - change `retention-days` value

**Add/remove platforms:**
Edit `workflows/build-all-platforms.yml` - comment out workflows

**Modify build triggers:**
Edit `on:` section in workflow files

### Advanced Changes

**Use self-hosted runners:**
Change `runs-on:` to your runner tags

**Add more platforms:**
Create new `workflows/build-<platform>.yml` based on existing ones

**Customize release notes:**
Edit template in `workflows/release.yml`

## 🐛 Troubleshooting

### Build Failed
1. Check workflow logs in GitHub Actions
2. Review error in specific step
3. See [GITHUB_ACTIONS_GUIDE.md](./GITHUB_ACTIONS_GUIDE.md) troubleshooting section

### Binary Not Running
1. Verify correct platform downloaded
2. Check file is executable: `chmod +x gcta64_*`
3. Try running with full path: `./gcta64_linux_x86_64`

### Release Not Created
1. Verify all builds completed
2. Check release.yml logs
3. Try manual trigger: `gh workflow run release.yml -f release_tag=v2.1.0`

## 📋 Checklist for First-Time Setup

- [ ] Clone repository
- [ ] Verify GitHub Actions enabled in Settings
- [ ] Push workflows: `git add .github && git commit && git push`
- [ ] Test with push to develop branch
- [ ] Monitor Actions tab for build completion
- [ ] Download and verify first binary
- [ ] Create first release (tag and push)
- [ ] Verify release in GitHub Releases
- [ ] Test downloaded binaries on target platforms

## 🔐 Security Notes

- No sensitive credentials in workflows
- Uses GitHub's automatic GITHUB_TOKEN
- All runners are isolated environments
- Build artifacts available publicly (by design)
- No changes to source code during builds

## 📖 Related Documentation

- **Build Scripts:** [docs/build/README.md](../docs/build/README.md)
- **Build Guide:** [docs/build/QUICK_START.md](../docs/build/QUICK_START.md)
- **Main README:** [README.md](../README.md)

## 🤝 Contributing

To modify workflows:

1. Edit workflow file in `.github/workflows/`
2. Test on feature branch
3. Submit PR with explanation of changes
4. Workflows from PR will run with new configuration

## 📞 Support

- **Questions about setup?** → See [GITHUB_ACTIONS_GUIDE.md](./GITHUB_ACTIONS_GUIDE.md)
- **Technical questions?** → See [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)
- **Workflow details?** → See [workflows/README.md](./workflows/README.md)
- **Build script details?** → See [docs/build/README.md](../docs/build/README.md)

## 🎯 Next Steps

1. **First time?** Read [GITHUB_ACTIONS_GUIDE.md](./GITHUB_ACTIONS_GUIDE.md)
2. **Technical details?** Read [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)
3. **Modifying workflows?** See [workflows/README.md](./workflows/README.md)
4. **New to GitHub Actions?** Check [GitHub Actions Docs](https://docs.github.com/en/actions)

---

**Last Updated:** February 2026  
**Status:** ✅ Production Ready
