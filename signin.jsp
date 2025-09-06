<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
    
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Moffat Bay Lodge</title>

  <!-- Fonts -->
  <link href="https://fonts.googleapis.com/css2?family=Lato:wght@300;400;700&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">

  <!-- External CSS -->
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
          <li><a href="#about">About</a></li>
          <li><a href="#accommodations">Accommodations</a></li>
          <li><a href="#dining">Dining</a></li>
          <li><a href="#activities">Activities</a></li>
          <li><a href="#contact">Contact</a></li>
          <!-- Auth buttons -->
          <li><a class="btn btn-ghost auth" href="#signin">Sign In</a></li>
          <li><a class="btn btn-primary auth" href="registration.jsp">Sign Up</a></li>
        </ul>
      </nav>
    </div>
  </header>

  <!-- ====== Hero ====== -->
  <section class="hero" role="region" aria-label="Scenic hero image">
    <div class="container hero-inner">
      <h1>A Luxurious Retreat in the Mountain Forest</h1>
      <p class="sub">Discover tranquility and comfort at our secluded lodge, nestled among towering trees and majestic peaks.</p>
      <a class="btn btn-primary" href="#book">Book Now</a>
    </div>
  </section>

  <!-- ====== About / Quick intro ====== -->
  <section id="signIn">
    <div class="container">
    	<form name="SignIn" action="signin.jsp" method="post">
			<%--Created a table to hold the first few fields in the form --%>
	    	<h3><label for="signIN">Sign In:</label></h3><br><br>
	    	
	    	<label for="userName">User Name:</label>
	    	<input type="text" id="userName" name="userName"><br><br>
	    	
	    	<label for="password">Password:</label>
	    	<input type="text" id="password" name="title"><br><br>
	    	
	    	
	    	
	    	<input type='submit' value='Submit'>
    	
    	</form>
    </div>
  </section>

  <!-- ====== Contact / Footer ====== -->
  <footer id="contact">
    <div class="container">
      <div class="grid">
        <div class="col-6">
          <h3 style="color:#f0e7d9">Contact</h3>
          <p>4070 Old Moffat Bay Rd, Hilton Beach, ON P0R 1G0, Canada</p>
          <p><a href="mailto:stay@moffatbay.com" style="color:var(--amber-glow)">stay@moffatbay.com</a> • (555) 555-0123</p>
        </div>
        <div class="col-6" style="display:flex; align-items:center; justify-content:flex-end; gap:10px">
          <a class="btn btn-ghost" href="#signin" aria-label="Sign in">Sign In</a>
          <a class="btn btn-primary" href="registration.jsp" aria-label="Sign up">Sign Up</a>
          <a class="btn btn-primary" href="#book" aria-label="Book now in footer">Book Now</a>
        </div>
      </div>
    </div>
  </footer>

</body>
</html>
