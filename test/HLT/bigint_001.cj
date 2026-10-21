//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.*
import std.io.*
import std.time.*
import std.regex.*
import std.math.*
import odbc4cj.*

@Test
public class bigint_001 {
    var conn: Connection
    var prepareStatement: Statement
    var rowCount: UpdateResult

    init() {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        conn = database.connect()
        prepareStatement = conn.prepareStatement("drop table if exists test")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(data bigint NOT NULL, datanull bigint)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
    }

    @TestCase
    public func bigint_001(): Unit {
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        prepareStatement.set<Int64>(0, Int64.Max)
        prepareStatement.set<Option<Int64>>(1, Option<Int64>.None)
        // prepareStatement.setNull(1)
        var rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlInt64", queryResult.columnInfos[0].typeName)
        @Assert("SqlInt64", queryResult.columnInfos[1].typeName)
        @Assert(Int64.Max, queryResult.get<Int64>(0))
        @Assert(None, queryResult.getOrNull<Int64>(1))
        queryResult.close()
    }
}
