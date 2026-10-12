// Runs the web app's real zod schemas over many inputs and records the first
// message per field — the ground truth the Dart validators must reproduce.
import { writeFileSync } from "node:fs";
// <repo>/test/fixtures -> ../../../ is the folder holding both repos.
const web = new URL(
  "../../../fox-passport-republic-app/src/shared/lib/schema.ts",
  import.meta.url,
).href;
const s = await import(web);

const firstByField = (r) => {
  if (r.success) return {};
  const out = {};
  for (const i of r.error.issues) {
    const k = String(i.path[0] ?? "");
    if (!(k in out)) out[k] = i.message;
  }
  return out;
};

const emails = ["ada@example.com","a@x.com","a+b@x.co","a@b","a..b@x.com",".a@x.com","a.@x.com","a@-x.com","a@x-.com","a@x.c","A@B.CO","a b@x.com","a@x.com ","  a@x.com  ","o'brien@x.com","a@sub.x.io","ñ@x.com","a@x.web1","","   ","plain","@x.com","a@.com","a@x..com","a_b@x.com","a-b@x.com","a%b@x.com","a@x_y.com","a@1.io","user@localhost","x@y.zz","a@x.com.","a@@x.com","a,b@x.com","a@x.c0m","-a@x.com","a@x.co m","\ta@x.com"];
const names = ["Ada Lovelace","Conan O'Brien","Jean-Luc Picard","Ana María","Dr. Cruz","R2D2","","  ","A","Al","Zoë","李小龍","Ada_99","<script>","Mary-Jane O'Neil","  Ada","Ada  ","O’Brien","Ada\nLovelace","José","ABC","a"];
const usernames = ["","a","ab","abc","fox_mulder","  ","ab ","日本語","x".repeat(60)];
const passwords = ["","short","abcdefghijklmnop","ABCDEFGHIJKLMNOP","Abcdefghijklmnop","Abcdefghijklmno1","Abcdefghijklmn1!","Abcdefghijklm1!x","Abcdefghijklmno1#","Abcdefghijklmno1&","Aa1!Aa1!Aa1!Aa1!","                ","Abcdefghijklmnopq","A1!aaaaaaaaaaaaa","a1!aaaaaaaaaaaaaa","A1!AAAAAAAAAAAAAA","Aa!aaaaaaaaaaaaaa","Aa1aaaaaaaaaaaaaa","Passw0rd","Passw0rd!","passw0rd","PASSW0RD","Abcdefg1","Abcdefgh","abcdefg1","ABCDEFG1","Abcdef1","A1b2C3d4","Éclair123!Éclair!"];
const codes = ["","1","12345","123456","1234567","12345a","abcdef","      ","12 456","１２３４５６"];

const base = { email:"ada@example.com", password:"Abcdefghijklmn1!", confirmPassword:"Abcdefghijklmn1!", username:"fox_mulder", name:"Ada Lovelace" };
const out = {};

out.loginEmail = emails.map(v => ({ input:v, message: firstByField(s.loginSchema.safeParse({ email:v, password:"x" })).email ?? null }));
out.loginPassword = ["","a"," ","password"].map(v => ({ input:v, message: firstByField(s.loginSchema.safeParse({ email:"a@x.co", password:v })).password ?? null }));
out.signupEmail = emails.map(v => ({ input:v, message: firstByField(s.signupSchema.safeParse({ ...base, email:v })).email ?? null }));
out.signupName = names.map(v => ({ input:v, message: firstByField(s.signupSchema.safeParse({ ...base, name:v })).name ?? null }));
out.signupUsername = usernames.map(v => ({ input:v, message: firstByField(s.signupSchema.safeParse({ ...base, username:v })).username ?? null }));
out.signupPassword = passwords.map(v => ({ input:v, message: firstByField(s.signupSchema.safeParse({ ...base, password:v, confirmPassword:v })).password ?? null }));
out.signupConfirm = [["Abcdefghijklmn1!","Abcdefghijklmn1!"],["Abcdefghijklmn1!","abcdefghijklmn1!"],["Abcdefghijklmn1!",""],["Abcdefghijklmn1!"," Abcdefghijklmn1!"],["Abcdefghijklmn1!","Abcdefghijklmn1! "]]
  .map(([p,c]) => ({ password:p, input:c, message: firstByField(s.signupSchema.safeParse({ ...base, password:p, confirmPassword:c })).confirmPassword ?? null }));
out.forgotEmail = emails.map(v => ({ input:v, message: firstByField(s.forgotPasswordSchema.safeParse({ email:v })).email ?? null }));
out.otpCode = codes.map(v => ({ input:v, message: firstByField(s.verifyEmailSchema.safeParse({ otpCode:v })).otpCode ?? null }));
out.resetCode = codes.map(v => ({ input:v, message: firstByField(s.resetPasswordSchema.safeParse({ otpCode:v, newPassword:"Abcdefg1", confirmPassword:"Abcdefg1" })).otpCode ?? null }));
out.resetNewPassword = passwords.map(v => ({ input:v, message: firstByField(s.resetPasswordSchema.safeParse({ otpCode:"123456", newPassword:v, confirmPassword:v })).newPassword ?? null }));
out.resetConfirm = [["Abcdefg1","Abcdefg1"],["Abcdefg1","abcdefg1"],["Abcdefg1",""]]
  .map(([p,c]) => ({ password:p, input:c, message: firstByField(s.resetPasswordSchema.safeParse({ otpCode:"123456", newPassword:p, confirmPassword:c })).confirmPassword ?? null }));

writeFileSync("test/fixtures/web_validation_vectors.json", JSON.stringify(out, null, 1));
const n = Object.values(out).reduce((a,v)=>a+v.length,0);
console.log("wrote", n, "vectors across", Object.keys(out).length, "rules");
