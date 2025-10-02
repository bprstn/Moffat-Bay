<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.util.List,java.util.Map,java.util.ArrayList,java.util.Optional" %>
<%@ page import="java.sql.Date,java.sql.SQLException" %>
<%@ page import="beans.BookingBean" %>
<jsp:useBean id="bookingBean" class="beans.BookingBean" scope="request" />

<%!
  private String h(String s){
    if (s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");
  }
%>

<%
  // Require login
  Long customerId = (Long) session.getAttribute("customerId");
  String customerEmail = (String) session.getAttribute("customerEmail");
  if (customerId == null) { response.sendRedirect("signin.jsp"); return; }

  request.setCharacterEncoding("UTF-8");

  String method = request.getMethod();
  String roomTypeIdStr = Optional.ofNullable(request.getParameter("room_type_id")).orElse("");
  String checkInStr    = Optional.ofNullable(request.getParameter("check_in")).orElse("");
  String checkOutStr   = Optional.ofNullable(request.getParameter("check_out")).orElse("");
  String guestsStr     = Optional.ofNullable(request.getParameter("guests")).orElse("");

  String errorMsg = null;
  String successMsg = null;
  String devError = null;

  List<Map<String,Object>> roomTypes = new ArrayList<>();
  try {
    roomTypes = bookingBean.listRoomTypes();
  } catch (Exception ex) {
    errorMsg = "Could not load room types.";
    devError = ex.getClass().getName() + ": " + ex.getMessage();
  }

  long newReservationId = 0L;
  Double quotedTotal = null;
  Double nightlyRate = null;

  if ("POST".equalsIgnoreCase(method) && errorMsg == null) {
    try {
      int roomTypeId = Integer.parseInt(roomTypeIdStr);
      int guests = Integer.parseInt(guestsStr);

      // Expect yyyy-mm-dd from <input type="date">
      Date checkIn  = Date.valueOf(checkInStr);
      Date checkOut = Date.valueOf(checkOutStr);

      if (!checkIn.before(checkOut)) {
        errorMsg = "Check-in must be before check-out.";
      } else {
        nightlyRate = bookingBean.getNightlyRate(roomTypeId);
        quotedTotal = bookingBean.quoteTotal(roomTypeId, checkIn, checkOut);

        if (!bookingBean.isAvailable(roomTypeId, checkIn, checkOut, guests)) {
          errorMsg = "Selected room type is not available for those dates or guest count.";
        } else {
          newReservationId = bookingBean.createReservation(customerId, roomTypeId, checkIn, checkOut, guests);
          if (newReservationId > 0L) {
            successMsg = "Reservation confirmed! ID #" + newReservationId + ".";
            // Clear form fields on success
            roomTypeIdStr = ""; checkInStr = ""; checkOutStr = ""; guestsStr = "";
          } else {
            errorMsg = "We couldn't create the reservation. Please try again.";
          }
        }
      }
    } catch (NumberFormatException nfe) {
      errorMsg = "Please select a room type and enter a valid guest count.";
    } catch (IllegalArgumentException iae) {
      errorMsg = "Please enter valid dates (YYYY-MM-DD).";
    } catch (Exception ex) {
      errorMsg = "Unexpected error while booking. Please try again.";
      devError = ex.getClass().getName() + ": " + ex.getMessage();
    }
  }
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Book a Room • Moffat Bay Lodge</title>
  <link href="https://fonts.googleapis.com/css2?family=Lato:wght@300;400;700&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="style.css?v=7">
</head>
<body>

<header role="banner">
  <div class="container nav" aria-label="Primary">
    <a class="brand" href="index.html">
      <img src="images/bear_logo.png" alt="Moffat Bay bear logo">
      <span>Moffat Bay Lodge</span>
    </a>
    <nav>
      <ul>
        <li><a href="about.html">About</a></li>
        <li><a href="amenities.html">amenities</a></li>
        <li><a href="dining.html">Dining</a></li>
        <li><a href="activities.html">Activities</a></li>
        <li><a href="contact.html">Contact</a></li>
        <li><span class="tag">Signed in: <%= h(customerEmail) %></span></li>
        <li><a class="btn btn-ghost auth" href="reservations.jsp">My Reservations</a></li>
        <li><a class="btn btn-ghost auth" href="signout.jsp">Sign Out</a></li>
      </ul>
    </nav>
  </div>
</header>

<section style="padding:40px 0">
  <div class="container" style="max-width:800px">
    <h2>Book a Room</h2>
    <p class="muted">Pick your dates and room type. We’ll confirm availability instantly.</p>

    <% if (errorMsg != null) { %>
      <div class="card" style="border-left:4px solid #b00020; margin:16px 0">
        <div class="pad">
          <strong>Error:</strong> <%= h(errorMsg) %>
          <% if (devError != null) { %>
          <pre class="muted" style="white-space:pre-wrap;margin-top:8px"><%= h(devError) %></pre>
          <% } %>
        </div>
      </div>
    <% } else if (successMsg != null) { %>
      <div class="card" style="border-left:4px solid #1e7f34; margin:16px 0">
        <div class="pad">
          <strong>Success:</strong> <%= h(successMsg) %>
          <div style="margin-top:10px">
            <a class="btn btn-primary" href="reservations.jsp">View My Reservations</a>
          </div>
        </div>
      </div>
    <% } %>

    <div class="card" style="margin-top:16px">
      <div class="pad">
        <form method="post" action="book.jsp" novalidate>
          <div class="grid">
            <div class="col-12">
              <label for="room_type_id"><strong>Room Type</strong></label>
              <select id="room_type_id" name="room_type_id" required>
                <option value="">-- Select a room type --</option>
                <% for (Map<String,Object> r : roomTypes) {
                     String id = String.valueOf(r.get("id"));
                     String code = String.valueOf(r.get("code"));
                     String name = String.valueOf(r.get("name"));
                     String rate = String.valueOf(r.get("nightly_rate"));
                     String cap  = String.valueOf(r.get("capacity"));
                     String selected = id.equals(roomTypeIdStr) ? "selected" : "";
                %>
                  <option value="<%= h(id) %>" <%= selected %>>
                    <%= h(name) %> (<%= h(code) %>) — $<%= h(rate) %>/night, sleeps <%= h(cap) %>
                  </option>
                <% } %>
              </select>
            </div>

            <div class="col-6">
              <label for="check_in"><strong>Check-in</strong></label>
              <input id="check_in" name="check_in" type="date" required value="<%= h(checkInStr) %>">
            </div>

            <div class="col-6">
              <label for="check_out"><strong>Check-out</strong></label>
              <input id="check_out" name="check_out" type="date" required value="<%= h(checkOutStr) %>">
            </div>

            <div class="col-6">
              <label for="guests"><strong>Guests</strong></label>
              <input id="guests" name="guests" type="number" min="1" step="1" required value="<%= h(guestsStr) %>">
            </div>

            <% if (quotedTotal != null) { %>
              <div class="col-6" style="display:flex; align-items:flex-end">
                <div class="tag">Estimated total: $<%= String.format(java.util.Locale.US, "%.2f", quotedTotal) %></div>
              </div>
            <% } %>

            <div class="col-12" style="margin-top:8px">
              <button type="submit" class="btn btn-primary">Book Now</button>
              <a href="reservations.jsp" class="btn btn-ghost" style="margin-left:8px">View My Reservations</a>
            </div>
          </div>
        </form>
      </div>
    </div>

  </div>
</section>

<footer id="contact">
  <div class="container">
    <div class="grid">
      <div class="col-6">
        <h3 style="color:#f0e7d9">Contact</h3>
        <p>4070 Old Moffat Bay Rd, Hilton Beach, ON P0R 1G0, Canada</p>
        <p><a href="mailto:stay@moffatbay.com" style="color:var(--amber-glow)">stay@moffatbay.com</a> • (555) 555-0123</p>
      </div>
      <div class="col-6" style="display:flex; align-items:center; justify-content:flex-end; gap:10px">
        <a class="btn btn-ghost" href="signout.jsp" aria-label="Sign out">Sign Out</a>
        <a class="btn btn-primary" href="reservations.jsp" aria-label="My reservations">My Reservations</a>
      </div>
    </div>
  </div>
</footer>

</body>
</html>
