﻿using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using AutoReporting.Models;

namespace AutoReporting.Controllers
{
	[Route("Pluralsight")]
    public class PluralsightController : Controller
    {
		[HttpGet]
		public IActionResult Pluralsight()
		{

			ViewData["Message"] = "Pluralsight User Management. Uses the Pluralsight License Management API to manage users.";

			return View();
		}

		[HttpPost]
		public async Task<IActionResult> Pluralsight(PluralsightModel model)
		{

			ViewData["Message"] = "Pluralsight User Management. Uses the Pluralsight License Management API to manage users. (Post)";
			await model.OnGet();
			ViewData["Response"] = model.users.toString();
			ViewData["UserList"] = model.users.data;
			ViewData["Update"] = DateTime.Now;
			model.users.data.Sort();
			return View();
		}

		[ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
		public IActionResult Error()
		{
			return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
		}
	}
}