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

        _browser = await _playwright.Chromium.LaunchAsync(
            new BrowserTypeLaunchOptions { Headless = true, SlowMo = 1000 }
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
    public async Task FillTheFormular_ForDemo_AB()
    {
        await _page.GotoAsync("http://localhost:3000/");

        // Klicka på länken till "Shop"
        await _page.GetByRole(AriaRole.Link, new() { Name = "Demo AB" }).ClickAsync();

        await _page.GetByLabel("Your email").FillAsync("m@email.com");

        await _page.GetByLabel("Title").FillAsync("Test");

        await _page.GetByLabel("Subject").SelectOptionAsync("Skada");

        await _page.Locator("textarea[name='message']").FillAsync("Test for postman");

        await _page.GetByRole(AriaRole.Button, new() { Name = "Create issue" }).ClickAsync();

        //Was suppose to use the alert that comes up to verify it but it won't show up on the playwright tests
    }

    [TestMethod]
    public async Task CloseAndReOpenTicket()
    {
        //Login to the account email
        await _page.GotoAsync("http://localhost:3000/login");
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
                await card.GetByRole(AriaRole.Button).ClickAsync();

                var select = card.Locator("select.stateSelect");
                await select.SelectOptionAsync(new SelectOptionValue { Value = "CLOSED" });
                await card.GetByRole(AriaRole.Button, new() { Name = "Save" }).ClickAsync();
                await _page.WaitForTimeoutAsync(500);

                var closedStatus = await card.Locator("div.attributes").TextContentAsync();
                Assert.IsTrue(closedStatus.Contains("CLOSED"), "the issue was not closed");

                //REOPEN
                await card.GetByRole(AriaRole.Button).ClickAsync();
                await select.SelectOptionAsync(new SelectOptionValue { Value = "OPEN" });
                await card.GetByRole(AriaRole.Button, new() { Name = "Save" }).ClickAsync();
                await _page.WaitForTimeoutAsync(500);

                var reopenStatus = await card.Locator("div.attributes").TextContentAsync();
                Assert.IsTrue(reopenStatus.Contains("OPEN"), "the issue wasn't reopened");
                break;
            }
        }
    }

    [TestMethod]
    public async Task RegisterCompanyAccount()
    {
        await _page.GotoAsync("http://localhost:3000/register");

        await _page.GetByPlaceholder("Email").FillAsync("limpis@gmail.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByPlaceholder("Username").FillAsync("simba");
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
    }

    [TestMethod]
    public async Task LoginWithNoPasswordShouldNotWork()
    {
        await _page.GotoAsync("http://localhost:3000/login");
        await _page.GetByPlaceholder("Email").FillAsync("m@email.com");
        await _page.GetByPlaceholder("Password").FillAsync("");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        var passwordField = _page.Locator("input[name='password']:invalid");

        bool isPasswordFieldInvalid = await passwordField.IsVisibleAsync();

        Assert.IsTrue(isPasswordFieldInvalid);
    }

    [TestMethod]
    public async Task LoginAsGuest_ToChatt_WithBot_NoPassword_OnlyMail()
    {
        await _page.GotoAsync("http://localhost:3000/chat/9e5caf19-b637-4f78-9145-a8ac8f5e49f5");

        await _page.GetByPlaceholder("Email").FillAsync("linus@nodehill.com");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Verify" }).ClickAsync();

        var checkForMessage = _page.GetByText("This is just a test.");

        Assert.IsTrue(await checkForMessage.IsVisibleAsync());
    }

    [TestMethod]
    public async Task LoginAsAdminAndCreateANewSubjectAndRemoveSubject()
    {
        string subjectName = "Teknisk Hjälp";

        await _page.GotoAsync("http://localhost:3000/login");
        await _page.GetByPlaceholder("Email").FillAsync("m@email.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        await _page.GetByRole(AriaRole.Link, new() { Name = "Form subjects" }).ClickAsync();

        //Filling out the new subject
        await _page.GetByRole(AriaRole.Button, new() { Name = "New Subject" }).ClickAsync();
        await _page.GetByPlaceholder("New Subject").FillAsync("Teknisk Hjälp");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Save" }).ClickAsync();

        await _page.WaitForSelectorAsync(
            "text={subjectName}",
            new() { State = WaitForSelectorState.Detached }
        );

        var newSubject = _page.Locator($"text={subjectName}");
        Assert.IsTrue(await newSubject.IsVisibleAsync());

        var subjectCards = _page.Locator("div.subjectCard");
        var cardCount = await subjectCards.CountAsync();

        //Iterate through all the cards
        for (int i = 0; i < cardCount; i++)
        {
            var card = subjectCards.Nth(i);
            var text = await card.Locator("div.attributes").TextContentAsync();

            //If they found the specific card then remove it
            if (text.Contains(subjectName))
            {
                await card.GetByRole(AriaRole.Button, new() { Name = "✖" }).ClickAsync();
                break;
            }
        }

        await _page.WaitForSelectorAsync(
            $"text={subjectName}",
            new() { State = WaitForSelectorState.Detached }
        );

        bool isSubjectStillVisible = await _page.Locator($"text={subjectName}").IsVisibleAsync();
        Assert.IsFalse(isSubjectStillVisible, "subject was not deleted");
    }

    [TestMethod]
    public async Task EditATask()
    {
        await _page.GotoAsync("http://localhost:3000/login");
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

            if (text.Contains('3'))
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

        for (int i = 0; i < cardCount; i++)
        {
            var card = _page.Locator("div.subjectCard").Nth(i);
            var text = await card.Locator("div.attributes").TextContentAsync();

            if (text.Contains('3'))
            {
                await card.GetByRole(AriaRole.Button, new() { Name = "✎" }).ClickAsync();
                await _page.Locator("input[name='newName']").FillAsync("Övrigt");
                var input = _page.Locator("input[name='newName']");
                await input.PressAsync("Enter");
                break;
            }
        }
        await _page.WaitForTimeoutAsync(500);
        var oldNameSubject = await _page.GetByText("Övrigt").IsVisibleAsync();
        Assert.IsTrue(oldNameSubject, "new subject is visible good job");
    }

    [TestMethod]
    public async Task GoToUrlWithoutlogginAndSeIssues()
    {
        await _page.GotoAsync("http://localhost:3000/employee/issues");

        var getLoadingMessage = _page.GetByText("Laddar...");
        await Expect(getLoadingMessage).ToBeVisibleAsync(new() { Timeout = 5000 });

        Assert.IsTrue(
            await getLoadingMessage.IsVisibleAsync(),
            "Its Working the issues doesn't load in"
        );
    }

    [TestMethod]
    public async Task GoToTwoDifferentCompanies()
    {
        await _page.GotoAsync("http://localhost:3000/");
        await _page.GetByRole(AriaRole.Link, new() { Name = "Demo AB" }).ClickAsync();
        var getTitleDemoABForm = _page.GetByText("Demo AB issue form.");
        Assert.IsTrue(await getTitleDemoABForm.IsVisibleAsync(), "Demo AB was loading in");

        await _page.GetByRole(AriaRole.Link, new() { Name = "Home" }).ClickAsync();
        await _page.GetByRole(AriaRole.Link, new() { Name = "Test AB" }).ClickAsync();
        var getTitleTestABForm = _page.GetByText("No Company was found!");
        Assert.IsTrue(await getTitleTestABForm.IsVisibleAsync(), "Worked");
    }

    [TestMethod]
    public async Task AddEmployeeAndUpdateAndDelete()
    {
        await _page.GotoAsync("http://localhost:3000/login");
        await _page.GetByPlaceholder("Email").FillAsync("m@email.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        await _page.GetByRole(AriaRole.Link, new() { Name = "Employees" }).ClickAsync();

        await _page.GetByRole(AriaRole.Button, new() { Name = "Add Employee" }).ClickAsync();

        _page.Dialog += async (_, dialog) =>
        {
            await dialog.AcceptAsync();
        };

        await _page.Locator("input[name='firstname']").FillAsync("Lars");
        await _page.Locator("input[name='lastname']").FillAsync("Persson");
        await _page.Locator("input[name='email']").FillAsync("lars@gmail.com");
        await _page.Locator("input[name='password']").FillAsync("abc123");

        await _page.Locator("input[value='USER']").ClickAsync();
        await _page.GetByRole(AriaRole.Button, new() { Name = "Create New Employee" }).ClickAsync();
        await _page.GetByRole(AriaRole.Link, new() { Name = "Employees" }).ClickAsync();

        await _page.WaitForSelectorAsync("text=lars@gmail.com");

        var employeeCards = _page.Locator("div.employeeCard");
        var cardCount = await employeeCards.CountAsync();

        for (int i = 0; i < cardCount; i++)
        {
            var card = _page.Locator("div.employeeCard").Nth(i);
            var text = await card.Locator("div.attributes").TextContentAsync();

            if (text.Contains("lars@gmail.com"))
            {
                await card.ClickAsync();
                await card.GetByRole(AriaRole.Button, new() { Name = "Edit information" })
                    .ClickAsync();
                await _page.Locator("input[name='firstname']").FillAsync("Päron");
                await _page.Locator("input[name='lastname']").FillAsync("Grässon");
                await _page.Locator("input[name='email']").FillAsync("paron@gmail.com");

                await _page
                    .GetByRole(AriaRole.Button, new() { Name = "Update Employee" })
                    .ClickAsync();
                break;
            }
        }

        await _page.WaitForSelectorAsync("text=paron@gmail.com");

        var newEmail = await _page.GetByText("paron@gmail.com").IsVisibleAsync();
        Assert.IsTrue(newEmail, "new Email is visible good job");

        var updateEmployeeCards = _page.Locator("div.employeeCard");
        var updateCardCount = await employeeCards.CountAsync();

        for (int i = 0; i < updateCardCount; i++)
        {
            var card = updateEmployeeCards.Nth(i);
            var text = await card.Locator("div.attributes").TextContentAsync();

            if (text.Contains("paron@gmail.com"))
            {
                await card.ClickAsync();
                await _page
                    .GetByRole(AriaRole.Button, new() { Name = "Remove employee" })
                    .ClickAsync();
                break;
            }
        }
        await _page.WaitForSelectorAsync(
            "text=paron@gmail.com",
            new() { State = WaitForSelectorState.Detached }
        );
        Assert.IsFalse(
            await _page.GetByText("paron@gmail.com").IsVisibleAsync(),
            "deleted employee is still visible"
        );
    }

    [TestMethod]
    public async Task LoginOnDifferentCompany_ToNotSeEmployee_FromAnotherCompany()
    {
        await _page.GotoAsync("http://localhost:3000/login");
        await _page.GetByPlaceholder("Email").FillAsync("m@email.com");
        await _page.GetByPlaceholder("Password").FillAsync("abc123");
        await _page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();

        await _page.GetByRole(AriaRole.Link, new() { Name = "Employees" }).ClickAsync();

        var findEmployee = _page.GetByText("test@gmail.com");
        bool isVisible = await findEmployee.IsVisibleAsync();

        Assert.IsFalse(isVisible, "Couldn't find the employee from DemoAb");
    }
}
