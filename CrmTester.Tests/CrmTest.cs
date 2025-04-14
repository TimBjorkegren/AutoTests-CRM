using System.Text.RegularExpressions;
using Microsoft.Playwright;
using Microsoft.Playwright.MSTest;

namespace PlaywrightTests;

[TestClass]
public class DemoTest : PageTest
{
    private IPlaywright? _playwright;
    private IBrowser? _browser;
    private IBrowserContext? _browserContext;
    private IPage? _page;

    [TestInitialize]
    public async Task Setup()
    {
        _playwright = await Microsoft.Playwright.Playwright.CreateAsync();

        var isHeadless = Environment.GetEnvironmentVariable("HEADLESS") == "true";
        _browser = await _playwright.Chromium.LaunchAsync(
            new BrowserTypeLaunchOptions
            {
                Headless = isHeadless,
                SlowMo = 1000, // Lägger in en fördröjning så vi kan se vad som händer
            }
        );
        _browserContext = await _browser.NewContextAsync();
        _page = await _browserContext.NewPageAsync();
    }

    [TestCleanup]
    public async Task Cleanup()
    {
        await _browserContext.CloseAsync();
        await _browser.CloseAsync();
        _playwright.Dispose();
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task FillTheFormular_ForDemo_AB()
    {
        await _page.GotoAsync("http://localhost:5173/");

        // Klicka på länken till "Shop"
        await _page.GetByRole(AriaRole.Link, new() { Name = "Demo AB" }).ClickAsync();

        await _page.GetByLabel("Your email").FillAsync("tim.bjorkegren@email.com");

        await _page.GetByLabel("Title").FillAsync("Test");

        await _page.GetByLabel("Subject").SelectOptionAsync("Skada");

        await _page.GetByRole(AriaRole.Button, new() { Name = "Create issue" }).ClickAsync();

        //Was suppose to use the alert that comes up to verify it but it won't show up on the playwright tests
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task LoginAndCloseATicket()
    {
        //Login to the account email
        await _page.GotoAsync("http://localhost:5173/login");
        await _page.GetByPlaceholder("Email").FillAsync("m@email.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        await _page.GetByRole(AriaRole.Link, new() { Name = "Issues" }).ClickAsync();

        var issueCards = _page.Locator("div.issueCard");

        var cardCount = await issueCards.CountAsync();

        //Iterate through all the cards
        for (int i = 0; i < cardCount; i++)
        {
            var card = issueCards.Nth(i);
            var text = await card.Locator("div.attributes").TextContentAsync();

            //If they found the specific card then update it
            if (text.Contains("Test Issue 2"))
            {
                var statusText = await card.Locator("div.attributes").TextContentAsync();
                if (statusText.Contains("CLOSED"))
                {
                    Console.WriteLine("its already closed :) ");
                    return;
                }

                await card.GetByRole(AriaRole.Button).ClickAsync();

                var select = card.Locator("select.stateSelect");
                await select.SelectOptionAsync(new SelectOptionValue { Value = "CLOSED" });

                await card.GetByRole(AriaRole.Button, new() { Name = "Save" }).ClickAsync();

                return;
            }
        }
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task LoginAndOpenATicket()
    {
        //Login to the account email
        await _page.GotoAsync("http://localhost:5173/login");
        await _page.GetByPlaceholder("Email").FillAsync("m@email.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        await _page.GetByRole(AriaRole.Link, new() { Name = "Issues" }).ClickAsync();

        var issueCards = _page.Locator("div.issueCard");

        var cardCount = await issueCards.CountAsync();

        //Iterate through all the cards
        for (int i = 0; i < cardCount; i++)
        {
            var card = issueCards.Nth(i);
            var text = await card.Locator("div.attributes").TextContentAsync();

            //If they found the specific card then update it
            if (text.Contains("Test Issue 2"))
            {
                var statusText = await card.Locator("div.attributes").TextContentAsync();
                if (statusText.Contains("OPEN"))
                {
                    Console.WriteLine("its already opened :) ");
                    return;
                }

                await card.GetByRole(AriaRole.Button).ClickAsync();

                var select = card.Locator("select.stateSelect");
                await select.SelectOptionAsync(new SelectOptionValue { Value = "OPEN" });

                await card.GetByRole(AriaRole.Button, new() { Name = "Save" }).ClickAsync();

                return;
            }
        }
    }

    /*
        [TestMethod]
        public async Task RegisterCompanyAccount()
        {
            await _page.GotoAsync("http://localhost:5173/register");
    
            await _page.GetByPlaceholder("Email").FillAsync("tim.bjorkegren@gmail.com");
            await _page.GetByPlaceholder("Password").FillAsync("abc123");
            await _page.GetByPlaceholder("Username").FillAsync("timtim");
            await _page.GetByPlaceholder("Company").FillAsync("MikroMjuk");
    
            await _page.GetByRole(AriaRole.Button, new() { Name = "Skapa konto" }).ClickAsync();
    
            var errorMessageAlert = _page.Locator("text=Company already exists.");
    
            bool accountAlreadyExist = await errorMessageAlert.IsVisibleAsync();
    
            if (accountAlreadyExist)
            {
                Console.WriteLine("The account already exists");
            }
            else
            {
                Console.WriteLine("New account was registered");
            }
        } */

    [TestMethod]
    [TestCategory("GUI")]
    public async Task LoginWithNoPasswordShouldNotWork()
    {
        await _page.GotoAsync("http://localhost:5173/login");
        await _page.GetByPlaceholder("Email").FillAsync("tim.bjorkegren@gmail.com");
        await _page.GetByPlaceholder("Password").FillAsync("");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        var passwordField = _page.Locator("input[name='password']:invalid");

        bool isPasswordFieldInvalid = await passwordField.IsVisibleAsync();

        Assert.IsTrue(isPasswordFieldInvalid);
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task LoginAsGuest_ToChatt_WithBot_NoPassword_OnlyMail()
    {
        await _page.GotoAsync("http://localhost:5173/chat/5f1f3181-1cb0-4832-b660-ac1caeeceae8");

        await _page.GetByPlaceholder("Email").FillAsync("tim.bjorkegren@gmail.com");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Verify" }).ClickAsync();

        var checkForMessage = _page.GetByText("Test for postman tim bjorkegren");

        Assert.IsTrue(await checkForMessage.IsVisibleAsync());
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task LoginAsAdminAndCreateANewSubject()
    {
        await _page.GotoAsync("http://localhost:5173/login");
        await _page.GetByPlaceholder("Email").FillAsync("m@email.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        await _page.GetByRole(AriaRole.Link, new() { Name = "Form subjects" }).ClickAsync();

        //Filling out the new subject
        await _page.GetByRole(AriaRole.Button, new() { Name = "New Subject" }).ClickAsync();
        await _page.GetByPlaceholder("New Subject").FillAsync("Teknisk Hjälp");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Save" }).ClickAsync();
        var newlyAddedSubject = _page.Locator("text=Teknisk Hjälp");
        string subjectName = "Teknisk Hjälp";

        var errorMessageLocator = _page.GetByText("undefined");

        if (await errorMessageLocator.IsVisibleAsync())
        {
            Console.WriteLine("subject already exist");
            Assert.IsTrue(true);
            return;
        }

        var newSubject = _page.Locator($"text={subjectName}");
        Assert.IsTrue(await newSubject.IsVisibleAsync(), "new subject was added");
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task LoginAsAdminAndRemoveSubject()
    {
        await _page.GotoAsync("http://localhost:5173/login");
        await _page.GetByPlaceholder("Email").FillAsync("m@email.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        await _page.GetByRole(AriaRole.Link, new() { Name = "Form subjects" }).ClickAsync();

        var subjectCards = _page.Locator("div.subjectCard");

        var cardCount = await subjectCards.CountAsync();

        //Iterate through all the cards
        for (int i = 0; i < cardCount; i++)
        {
            var card = subjectCards.Nth(i);
            var text = await card.Locator("div.attributes").TextContentAsync();

            //If they found the specific card then remove it
            if (text.Contains("Teknisk Hjälp"))
            {
                await card.GetByRole(AriaRole.Button, new() { Name = "✖" }).ClickAsync();
                break;
            }
        }
        await _page.WaitForTimeoutAsync(500);
        var isSubjectStillVisible = await _page.GetByText("Teknisk Hjälp").IsVisibleAsync();
        Assert.IsFalse(isSubjectStillVisible, "subject is still visible");
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task EditATask()
    {
        await _page.GotoAsync("http://localhost:5173/login");
        await _page.GetByPlaceholder("Email").FillAsync("m@email.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        await _page.GetByRole(AriaRole.Link, new() { Name = "Form subjects" }).ClickAsync();

        var subjectCards = _page.Locator("div.subjectCard");

        var cardCount = await subjectCards.CountAsync();
        var randomText = "Test-" + Guid.NewGuid().ToString("N").Substring(0, 6);

        for (int i = 0; i < cardCount; i++)
        {
            var card = _page.Locator("div.subjectCard").Nth(i);
            var text = await card.Locator("div.attributes").TextContentAsync();

            if (text.Contains('4'))
            {
                await card.GetByRole(AriaRole.Button, new() { Name = "✎" }).ClickAsync();
                await _page.Locator("input[name='newName']").FillAsync(randomText);
                var input = _page.Locator("input[name='newName']");
                await input.PressAsync("Enter");
                break;
            }
        }
        await _page.WaitForTimeoutAsync(500);
        var newNameSubject = await _page.GetByText(randomText).IsVisibleAsync();
        Assert.IsTrue(newNameSubject, "new subject is visible good job");
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task GoToUrlWithoutlogginAndSeIssues()
    {
        await _page.GotoAsync("http://localhost:5173/employee/issues");

        var getLoadingMessage = _page.GetByText("Laddar...");
        await Expect(getLoadingMessage).ToBeVisibleAsync(new() { Timeout = 5000 });

        Assert.IsTrue(
            await getLoadingMessage.IsVisibleAsync(),
            "Its Working the issues doesn't load in"
        );
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task GoToTwoDifferentCompanies()
    {
        await _page.GotoAsync("http://localhost:5173/");
        await _page.GetByRole(AriaRole.Link, new() { Name = "Demo AB" }).ClickAsync();
        var getTitleDemoABForm = _page.GetByText("Demo AB issue form.");
        Assert.IsTrue(await getTitleDemoABForm.IsVisibleAsync(), "Demo AB was loading in");

        await _page.GetByRole(AriaRole.Link, new() { Name = "Home" }).ClickAsync();
        await _page.GetByRole(AriaRole.Link, new() { Name = "Test AB" }).ClickAsync();
        var getTitleTestABForm = _page.GetByText("Test AB issue form.");
        Assert.IsTrue(await getTitleTestABForm.IsVisibleAsync(), "Test AB was loading in");
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task UpdateAEmployee()
    {
        await _page.GotoAsync("http://localhost:5173/login");
        await _page.GetByPlaceholder("Email").FillAsync("m@email.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        await _page.GetByRole(AriaRole.Link, new() { Name = "Employees" }).ClickAsync();

        var employeeCards = _page.Locator("div.employeeCard");

        var cardCount = await employeeCards.CountAsync();
        var randomText = "Test-" + Guid.NewGuid().ToString("N").Substring(0, 6);
        var randomText2 = "Test-" + Guid.NewGuid().ToString("N").Substring(0, 6);
        var randomEmail = "Test-" + Guid.NewGuid().ToString("N").Substring(0, 6) + "@gmail.com";

        for (int i = 0; i < cardCount; i++)
        {
            var card = _page.Locator("div.employeeCard").Nth(i);
            var text = await card.Locator("div.attributes").TextContentAsync();

            if (text.Contains("Tim_bjork"))
            {
                await card.ClickAsync();
                await card.GetByRole(AriaRole.Button, new() { Name = "Edit information" })
                    .ClickAsync();
                await _page.Locator("input[name='firstname']").FillAsync(randomText);
                await _page.Locator("input[name='lastname']").FillAsync(randomText2);
                await _page.Locator("input[name='email']").FillAsync(randomEmail);

                await card.GetByRole(AriaRole.Button, new() { Name = "Update Employee" })
                    .ClickAsync();
                break;
            }
        }
        await _page.WaitForTimeoutAsync(500);
        var newEmail = await _page.GetByText(randomEmail).IsVisibleAsync();
        Assert.IsTrue(newEmail, "new Email is visible good job");
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task AddRandomEmployee()
    {
        await _page.GotoAsync("http://localhost:5173/login");
        await _page.GetByPlaceholder("Email").FillAsync("m@email.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        await _page.GetByRole(AriaRole.Link, new() { Name = "Employees" }).ClickAsync();

        var randomText = "Test-" + Guid.NewGuid().ToString("N").Substring(0, 6);
        var randomText2 = "Test-" + Guid.NewGuid().ToString("N").Substring(0, 6);
        var randomEmail = "Test-" + Guid.NewGuid().ToString("N").Substring(0, 6) + "@gmail.com";
        var randomPassword = "Test-" + Guid.NewGuid().ToString("N").Substring(0, 6);

        await _page.GetByRole(AriaRole.Button, new() { Name = "Add Employee" }).ClickAsync();

        _page.Dialog += async (_, dialog) =>
        {
            await dialog.AcceptAsync();
        };

        await _page.Locator("input[name='firstname']").FillAsync(randomText);
        await _page.Locator("input[name='lastname']").FillAsync(randomText2);
        await _page.Locator("input[name='email']").FillAsync(randomEmail);
        await _page.Locator("input[name='password']").FillAsync(randomPassword);

        await _page.Locator("input[value='USER']").ClickAsync();
        await _page.GetByRole(AriaRole.Button, new() { Name = "Create New Employee" }).ClickAsync();
        await _page.GetByRole(AriaRole.Link, new() { Name = "Employees" }).ClickAsync();

        var newEmail = await _page.GetByText(randomEmail).IsVisibleAsync();
        Assert.IsTrue(newEmail, "new email is visible good job");
    }

    [TestMethod]
    [TestCategory("GUI")]
    public async Task LoginOnDifferentCompany_ToNotSeEmployee_FromAnotherCompany()
    {
        await _page.GotoAsync("http://localhost:5173/login");
        await _page.GetByPlaceholder("Email").FillAsync("testy@gmail.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        await _page.GetByRole(AriaRole.Link, new() { Name = "Employees" }).ClickAsync();

        var findEmployee = _page.GetByText("m@email.com");
        bool isVisible = await findEmployee.IsVisibleAsync();

        Assert.IsFalse(isVisible, "Couldn't find the employee from DemoAb");
    }
}
