//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.*
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*

@Test
public class OdbcTest {
    init() {
    }
    
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data varchar(50) NOT NULL, datanull varchar(20))")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        prepareStatement.set<String>(0, "萨菲罗斯经历过是")
        prepareStatement.set<Option<String>>(1, Option<String>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        println(rowCount.rowCount)
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlString", queryResult.columnInfos[0].typeName)
        @Assert("SqlString", queryResult.columnInfos[1].typeName)
        @Assert("萨菲罗斯经历过是", queryResult.get<String>(0))
        @Assert(None, queryResult.getOrNull<String>(1))
        queryResult.close()
    }
}
