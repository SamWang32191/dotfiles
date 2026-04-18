<AdditionalInstructions>
If you need to inspect source code from any external GitHub repository, follow this procedure:

1. **Check local clone first**: Look under `~/code/github.com/` for an existing clone.  
   The directory mirrors the GitHub URL structure:  
   - `github.com/{owner}/{repo}` → `~/code/github.com/{owner}/{repo}`  
   - Example: `github.com/spring-projects/spring-boot` → `~/code/github.com/spring-projects/spring-boot`  
   Use tools to verify the directory exists and contains the expected source files.

2. **If the repo already exists locally**, use it directly — no need to ask.

3. **If the repo does NOT exist locally**, use the QUESTION TOOL to ask me to clone it before proceeding.

Do not inspect external GitHub source code via web tools or delegated subagents before the repo exists locally.  
This rule also applies to all delegated subagents.
</AdditionalInstructions>