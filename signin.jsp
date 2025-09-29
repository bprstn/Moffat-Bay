<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<%@ page import="beans.SigninBean" %>
<jsp:useBean id="signinBean" class="beans.SigninBean" scope="request" />

<%!
  // Simple HTML escape
  private String h(String s){
    if (s == null) return "";
    return s.replace("&","&amp;")
            .replace("<","&lt;")
            .replace(">","&gt;")
            .replace("\"","&quot;");
  }
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Sign In • Moffat Bay Lodge</title>

  <!-- Fonts -->
  <link href="https://fonts.googleapis.com/css2?family=Lato:wght@300;400;700&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">

  <!-- External CSS (cache-busted once) -->
  <link rel="stylesheet" href="style.css?v=5">
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
          <li><a href="about.html">About</a></li>
          <li><a href="index.html#accommodations">Accommodations</a></li>
          <li><a href="index.html#dining">Dining</a></li>
          <li><a href="activities.html">Activities</a></li>
          <li><a href="contact.html">Contact</a></li>
          <!-- Auth buttons -->
          <li><a class="btn btn-ghost auth" href="signin.jsp">Sign In</a></li>
          <li><a class="btn btn-primary auth" href="registration.jsp">Sign Up</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <section style="padding:40px 0">
    <div class="container" style="max-width:700px">
      <h2>Sign in to your account</h2>
      <p class="muted">Access your reservations and profile.</p>

      <%
        request.setCharacterEncoding("UTF-8");
        String method = request.getMethod();
        String email = "";
        String password = "";
        String errorMsg = null;

        if ("POST".equalsIgnoreCase(method)) {
          email = Optional.ofNullable(request.getParameter("email")).orElse("").trim().toLowerCase();
          password = Optional.ofNullable(request.getParameter("password")).orElse("");

          if (email.isEmpty() || password.isEmpty()) {
            errorMsg = "Please enter your email and password.";
          } else {
            try {
              long id = signinBean.authenticate(email, password);
              if (id > 0L) {
                // Success: set session and redirect
                session.setAttribute("customerId", id);
                session.setAttribute("customerEmail", email);
                response.sendRedirect("reservations.jsp");
                return;
              } else {
                errorMsg = "Invalid email or password.";
              }
            } catch (Exception ex) {
              errorMsg = "An unexpected error occurred during sign in.";
              request.setAttribute("devError", ex.getClass().getName() + ": " + ex.getMessage());
            }
          }
        }
      %>

      <% if (errorMsg != null) { %>
        <div class="card" style="border-left:4px solid #b00020; margin:16px 0">
          <div class="pad">
            <strong>Error:</strong> <span><%= h(errorMsg) %></span>
            <% if (request.getAttribute("devError") != null) { %>
              <pre class="muted" style="white-space:pre-wrap;margin-top:8px"><%= h((String)request.getAttribute("devError")) %></pre>
            <% } %>
          </div>
        </div>
      <% } %>

      <div class="card" style="margin-top:16px">
        <div class="pad">
          <form name="SignIn" action="signin.jsp" method="post" novalidate>
            <div class="grid">
              <div class="col-12">
                <label for="email"><strong>Email</strong></label>
                <input id="email" name="email" type="email" required
                       value="<%= h(email) %>">
              </div>

              <div class="col-12">
                <label for="password"><strong>Password</strong></label>
                <input id="password" name="password" type="password" required>
              </div>

              <div class="col-12" style="margin-top:8px">
                <button type="submit" class="btn btn-primary">Sign In</button>
                <a href="registration.jsp" class="btn btn-ghost" style="margin-left:8px">Create an account</a>
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
