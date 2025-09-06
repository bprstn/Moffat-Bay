<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<%@ page import="beans.CustomerBean" %>
<jsp:useBean id="customerBean" class="beans.CustomerBean" scope="request" />

<%!
// Simple HTML escaper to avoid external libs
private String h(String s){
  if (s == null) return "";
  String out = s;
  out = out.replace("&","&amp;");
  out = out.replace("<","&lt;");
  out = out.replace(">","&gt;");
  out = out.replace("\"","&quot;");
  return out;
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Register • Moffat Bay Lodge</title>

  <!-- Fonts -->
  <link href="https://fonts.googleapis.com/css2?family=Lato:wght@300;400;700&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">

  <!-- Site CSS -->
  <link rel="stylesheet" href="style.css">
</head>
<body>

  <!-- ====== Header / Nav ====== -->
  <header role="banner">
    <div class="container nav" aria-label="Primary">
      <a class="brand" href="index.html">
        <img src="images/bear_logo.png" alt="Moffat Bay bear logo">
        <span>Moffat Bay Lodge</span>
      </a>

      <nav>
        <ul>
          <li><a href="index.html#about">About</a></li>
          <li><a href="index.html#accommodations">Accommodations</a></li>
          <li><a href="index.html#dining">Dining</a></li>
          <li><a href="index.html#activities">Activities</a></li>
          <li><a href="index.html#contact">Contact</a></li>
          <li><a class="btn btn-ghost auth" href="signin.jsp">Sign In</a></li>
          <li><a class="btn btn-primary auth" href="registration.jsp">Sign Up</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <!-- ====== Registration Form ====== -->
  <section style="padding:40px 0">
    <div class="container" style="max-width:700px">
      <h2>Create your account</h2>
      <p class="muted">Join Moffat Bay to book rooms, track reservations, and manage your profile.</p>

      <%
        request.setCharacterEncoding("UTF-8");

        String method = request.getMethod();
        String firstName = "";
        String lastName  = "";
        String email     = "";
        String phone     = "";
        String password  = "";
        String confirm   = "";

        String errorMsg  = null;
        String successMsg= null;

        if ("POST".equalsIgnoreCase(method)) {
          firstName = Optional.ofNullable(request.getParameter("first_name")).orElse("").trim();
          lastName  = Optional.ofNullable(request.getParameter("last_name")).orElse("").trim();
          email     = Optional.ofNullable(request.getParameter("email")).orElse("").trim().toLowerCase();
          phone     = Optional.ofNullable(request.getParameter("phone")).orElse("").trim();
          password  = Optional.ofNullable(request.getParameter("password")).orElse("");
          confirm   = Optional.ofNullable(request.getParameter("confirm_password")).orElse("");

          if (firstName.isEmpty() || lastName.isEmpty() || email.isEmpty() || password.isEmpty() || confirm.isEmpty()) {
            errorMsg = "Please fill in all required fields.";
          } else if (!password.equals(confirm)) {
            errorMsg = "Passwords do not match.";
          } else if (email.length() > 255 || firstName.length() > 100 || lastName.length() > 100) {
            errorMsg = "One or more fields exceed the allowed length.";
          } else {
            try {
              boolean exists = customerBean.emailExists(email);
              if (exists) {
                errorMsg = "An account with that email already exists. Please sign in or use a different email.";
              } else {
                long newId = customerBean.registerCustomer(firstName, lastName, email, phone, password);
                if (newId > 0L) {
                  successMsg = "Registration successful! You can now sign in.";
                  firstName = lastName = email = phone = "";
                } else {
                  errorMsg = "Registration failed. Please try again.";
                }
              }
            } catch (Exception ex) {
              errorMsg = "An unexpected error occurred. Please try again.";
              ex.printStackTrace(); // to catalina.out for debug
            }
          }
        }
      %>

      <!-- Feedback banners -->
      <%
        if (errorMsg != null) {
      %>
        <div class="card" style="border-left:4px solid #b00020; margin:16px 0">
          <div class="pad">
            <strong>Error:</strong> <span><%= h(errorMsg) %></span>
          </div>
        </div>
      <%
        } else if (successMsg != null) {
      %>
        <div class="card" style="border-left:4px solid #1e7f34; margin:16px 0">
          <div class="pad">
            <strong>Success:</strong> <span><%= h(successMsg) %></span>
            <div style="margin-top:10px">
              <a class="btn btn-primary" href="signin.jsp">Go to Sign In</a>
            </div>
          </div>
        </div>
      <%
        }
      %>

      <div class="card" style="margin-top:16px">
        <div class="pad">
          <form method="post" action="registration.jsp" novalidate>
            <div class="grid">
              <div class="col-6">
                <label for="first_name"><strong>First Name</strong></label>
                <input id="first_name" name="first_name" type="text" required
                       value="<%= h(firstName) %>"
                       style="width:100%;padding:.75rem;border:1px solid #d6d6d6;border-radius:10px;margin-top:.35rem">
              </div>

              <div class="col-6">
                <label for="last_name"><strong>Last Name</strong></label>
                <input id="last_name" name="last_name" type="text" required
                       value="<%= h(lastName) %>"
                       style="width:100%;padding:.75rem;border:1px solid #d6d6d6;border-radius:10px;margin-top:.35rem">
              </div>

              <div class="col-6">
                <label for="email"><strong>Email</strong></label>
                <input id="email" name="email" type="email" required
                       value="<%= h(email) %>"
                       style="width:100%;padding:.75rem;border:1px solid #d6d6d6;border-radius:10px;margin-top:.35rem">
              </div>

              <div class="col-6">
                <label for="phone"><strong>Phone (optional)</strong></label>
                <input id="phone" name="phone" type="tel"
                       value="<%= h(phone) %>"
                       style="width:100%;padding:.75rem;border:1px solid #d6d6d6;border-radius:10px;margin-top:.35rem">
              </div>

              <div class="col-6">
                <label for="password"><strong>Password</strong></label>
                <input id="password" name="password" type="password" required minlength="8"
                       style="width:100%;padding:.75rem;border:1px solid #d6d6d6;border-radius:10px;margin-top:.35rem">
                <p class="muted" style="margin:.4rem 0 0;font-size:.9rem">Use at least 8 characters.</p>
              </div>

              <div class="col-6">
                <label for="confirm_password"><strong>Confirm Password</strong></label>
                <input id="confirm_password" name="confirm_password" type="password" required minlength="8"
                       style="width:100%;padding:.75rem;border:1px solid #d6d6d6;border-radius:10px;margin-top:.35rem">
              </div>

              <div class="col-12" style="grid-column: span 12; margin-top:8px">
                <button type="submit" class="btn btn-primary">Create Account</button>
                <a href="signin.jsp" class="btn btn-ghost" style="margin-left:8px">I already have an account</a>
              </div>
            </div>
          </form>
        </div>
      </div>

    </div>
  </section>

  <!-- ====== Footer ====== -->
  <footer id="contact">
    <div class="container">
      <div class="grid">
        <div class="col-6">
          <h3 style="color:#f0e7d9">Contact</h3>
          <p>4070 Old Moffat Bay Rd, Hilton Beach, ON P0R 1G0, Canada</p>
          <p><a href="mailto:stay@moffatbay.com" style="color:var(--amber-glow)">stay@moffatbay.com</a> • (555) 555-0123</p>
        </div>
        <div class="col-6" style="display:flex; align-items:center; justify-content:flex-end; gap:10px">
          <a class="btn btn-ghost" href="signin.jsp" aria-label="Sign in">Sign In</a>
          <a class="btn btn-primary" href="registration.jsp" aria-label="Sign up">Sign Up</a>
          <a class="btn btn-primary" href="book.jsp" aria-label="Book now in footer">Book Now</a>
        </div>
      </div>
    </div>
  </footer>

</body>
</html>
