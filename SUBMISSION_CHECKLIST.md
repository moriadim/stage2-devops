# Submission Checklist

## Part A Files Required

- [x] docker-compose.yml
- [x] nginx.conf.template  
- [x] entrypoint.sh
- [x] README.md
- [x] DECISION.md (optional but included)
- [ ] .env.example (create manually - content below)

Create `.env.example` with this content:
```
BLUE_IMAGE=your-blue-image:tag
GREEN_IMAGE=your-green-image:tag
ACTIVE_POOL=blue
RELEASE_ID_BLUE=release-blue-001
RELEASE_ID_GREEN=release-green-001
PORT=3000
```

## Part B Files Required

- [x] DEPLOYMENT_RESEARCH.md (ready to copy to Google Doc)

## Steps to Submit

### 1. Create .env.example file manually
Create the file in your repo with the content shown above.

### 2. Create GitHub Repository
```bash
# Initialize git
git init
git add .
git commit -m "Blue/Green deployment setup"
git branch -M main

# Create repo on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

### 3. Create Google Doc
- Go to Google Docs
- Create new document
- Copy entire contents of `DEPLOYMENT_RESEARCH.md` into it
- Share: "Anyone with the link can view"
- Copy the link

### 4. Submit via Slack
In the `stage-2-devops` channel, run:
```
/stage-two-devops
```

Then provide:
- Your full name
- Slack display name  
- IP address
- GitHub repo URL (format: https://github.com/username/repo)
- Link to your Google Doc

## Files You Have

All files are present and ready:
- docker-compose.yml ✓
- nginx.conf.template ✓
- entrypoint.sh ✓
- README.md ✓
- DECISION.md ✓
- DEPLOYMENT_RESEARCH.md ✓
- test.sh ✓
- validate_setup.sh ✓
- Makefile ✓

## What You Need to Do

1. Manually create `.env.example` file (copy the content above)
2. Push to GitHub
3. Copy DEPLOYMENT_RESEARCH.md to Google Docs and make it viewable
4. Submit via Slack command

Deadline: 11:59 PM GMT, October 29th, 2025

