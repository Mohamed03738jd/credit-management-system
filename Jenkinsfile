cd ~/credit-management-system

git add Jenkinsfile
git commit -m "add: jenkinsfile CI/CD pipeline"
git push origin main
```

---

### Créer le pipeline dans Jenkins
```
1. http://localhost:9091
2. New Item
3. Nom : credit-management-pipeline
4. Type : Pipeline → OK

5. General :
   ✅ GitHub project
   URL : https://github.com/Mohamed03738jd/credit-management-system/

6. Build Triggers :
   ✅ GitHub hook trigger for GITScm polling

7. Pipeline :
   Definition  : Pipeline script from SCM
   SCM         : Git
   URL         : https://github.com/Mohamed03738jd/credit-management-system.git
   Credentials : github-credentials
   Branch      : */main
   Script Path : Jenkinsfile

8. Save
9. Build Now  ← tester manuellement d'abord